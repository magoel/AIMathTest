import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { GoogleGenerativeAI } from "@google/generative-ai";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const geminiApiKey = defineSecret("GEMINI_API_KEY");

interface GenerateTestRequest {
  profileId: string;
  grade: number;
  topics: string[];
  difficulty: number;
  questionCount: number;
  timed: boolean;
}

interface Question {
  id: string;
  type: string;
  question: string;
  correctAnswer: string;
  topic: string;
}

function generateShareCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 5; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return `MATH-${code}`;
}

export const generateTest = onCall(
  { secrets: [geminiApiKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be logged in");
    }

    const { profileId, grade, topics, difficulty, questionCount, timed } =
      request.data as GenerateTestRequest;

    if (!topics || topics.length === 0) {
      throw new HttpsError("invalid-argument", "At least one topic required");
    }

    const parentId = request.auth.uid;

    // Fetch recent attempts for personalization
    const recentAttempts = await db
      .collection("attempts")
      .where("parentId", "==", parentId)
      .where("profileId", "==", profileId)
      .orderBy("completedAt", "desc")
      .limit(20)
      .get();

    // Analyze weak areas
    const weakTopics: string[] = [];
    const strongTopics: string[] = [];
    const topicScores: Record<string, number[]> = {};

    for (const doc of recentAttempts.docs) {
      const attempt = doc.data();
      if (attempt.testTopics) {
        for (const topic of attempt.testTopics) {
          if (!topicScores[topic]) topicScores[topic] = [];
          topicScores[topic].push(attempt.percentage || 0);
        }
      }
    }

    for (const [topic, scores] of Object.entries(topicScores)) {
      const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
      if (avg < 70) weakTopics.push(topic);
      else if (avg >= 85) strongTopics.push(topic);
    }

    // Build AI prompt
    const gradeLabel = grade === 0 ? "Kindergarten" : `Grade ${grade}`;
    const prompt = `You are a math test generator for a ${gradeLabel} student.

Generate exactly ${questionCount} math problems with these requirements:
- Topics: ${topics.join(", ")}
- Difficulty level: ${difficulty}/10
- Format: Fill-in-the-blank with numeric answers only
${weakTopics.length > 0 ? `\nStudent's weak areas: ${weakTopics.join(", ")}` : ""}
${strongTopics.length > 0 ? `\nStudent's strong areas: ${strongTopics.join(", ")}` : ""}

Include:
- ${weakTopics.length > 0 ? "30% problems targeting weak areas" : "Balanced mix of problems"}
- 50% problems at requested difficulty
- 20% slightly challenging problems

Return ONLY a valid JSON array with no extra text, no markdown, no code fences:
[{"question":"24 × 15 = ?","answer":"360","topic":"multiplication"}]`;

    try {
      const apiKey = geminiApiKey.value();
      if (!apiKey) {
        throw new Error("GEMINI_API_KEY secret not configured");
      }

      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({
        model: "gemini-2.0-flash",
        generationConfig: {
          responseMimeType: "application/json",
        },
      });

      const result = await model.generateContent(prompt);
      const text = result.response.text();

      // Parse response
      let jsonStr = text.trim();
      if (jsonStr.startsWith("```")) {
        jsonStr = jsonStr
          .replace(/^```(?:json)?\n?/, "")
          .replace(/\n?```$/, "");
      }

      const parsed = JSON.parse(jsonStr);

      const questions: Question[] = parsed.map(
        (q: { question: string; answer: string; topic: string }, i: number) => ({
          id: `q${i + 1}`,
          type: "fill_in_blank",
          question: q.question,
          correctAnswer: String(q.answer),
          topic: q.topic,
        })
      );

      // Save test to Firestore
      const testRef = db.collection("tests").doc();
      const testId = testRef.id;
      const shareCode = generateShareCode();
      const now = admin.firestore.Timestamp.now();
      const expiresAt = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 90 * 24 * 60 * 60 * 1000)
      );

      await testRef.set({
        shareCode,
        createdBy: { parentId, profileId, profileName: "" },
        config: { topics, difficulty, questionCount, timed, timeLimitSeconds: timed ? questionCount * 60 : null },
        questions: questions.map((q) => ({
          id: q.id, type: q.type, question: q.question,
          correctAnswer: q.correctAnswer, topic: q.topic,
        })),
        createdAt: now,
        expiresAt,
      });

      return { testId, shareCode, questions };
    } catch (error: unknown) {
      console.error("Error generating test:", error);
      const message = error instanceof Error ? error.message : "Unknown error";
      throw new HttpsError("internal", message);
    }
  }
);
