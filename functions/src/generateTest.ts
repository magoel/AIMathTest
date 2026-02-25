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
  board?: string;
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
  choices?: string[];
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

    const { profileId, grade, board, topics, difficulty, questionCount, timed } =
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
    const boardLabel = board === "ib" ? "IB (International Baccalaureate)"
      : board === "cambridge" ? "Cambridge International"
      : "CBSE";

    const mcqCount = Math.max(1, Math.round(questionCount * 0.4));
    const fibCount = questionCount - mcqCount;

    const prompt = `You are an expert ${boardLabel} math teacher creating an engaging test for a ${gradeLabel} student.

Generate exactly ${questionCount} math problems (${fibCount} fill-in-blank + ${mcqCount} multiple-choice).

TOPICS: ${topics.join(", ")}
DIFFICULTY: ${difficulty}/10
BOARD: ${boardLabel}

═══ QUESTION VARIETY (MANDATORY) ═══
- At least 40% must be WORD PROBLEMS with real-world context (shopping, travel, cooking, sports, etc.)
- No more than 30% should be bare arithmetic like "X + Y = ?"
- Include multi-step problems, pattern recognition, and applied math
- Make questions age-appropriate and engaging for ${gradeLabel} students

═══ QUESTION TYPES ═══
- "fill_in_blank" (${fibCount} questions): Student types a numeric answer. Good for computation and short answers.
- "multiple_choice" (${mcqCount} questions): Student picks from exactly 4 options. Good for conceptual questions, estimation, word problems. Include a "choices" array with 4 options. The correct answer must be one of the choices.

═══ MATH NOTATION ═══
Use LaTeX notation wrapped in dollar signs for mathematical expressions:
- Fractions: $\\frac{2}{3}$
- Exponents: $x^2$, $3^4$
- Square roots: $\\sqrt{16}$
- Use × for multiplication, ÷ for division in plain text
- Keep it simple for ${gradeLabel} — use LaTeX only where it improves readability

═══ DIFFICULTY SCALING (${difficulty}/10) ═══
- Level 1-3: Single-step, small numbers, direct application. Example: "Riya has 8 apples. She gives 3 to her friend. How many does she have left?"
- Level 4-6: Multi-step, moderate numbers, some reasoning. Example: "A shop sells notebooks for ₹45 each. If Amit buys 6 notebooks and pays with a ₹500 note, how much change does he get?"
- Level 7-8: Complex, combines concepts, real-world application. Example: "A rectangular garden is 12m long and 8m wide. A path 1m wide runs around the outside. What is the area of the path?"
- Level 9-10: Competition-level, creative problem solving. Example: "Find the smallest 3-digit number that leaves a remainder of 2 when divided by 3, 5, and 7."

═══ BOARD-SPECIFIC STYLE ═══
${boardLabel === "CBSE" ? "Use Indian context (₹ currency, Indian names like Riya/Amit/Priya, Indian units, NCERT-style phrasing)" : ""}
${boardLabel.includes("IB") ? "Use inquiry-based framing, international context, encourage mathematical thinking" : ""}
${boardLabel.includes("Cambridge") ? "Use British English, precise mathematical language, structured problem format" : ""}

${weakTopics.length > 0 ? `\nSTUDENT'S WEAK AREAS: ${weakTopics.join(", ")} — Include 30% problems targeting these.` : ""}
${strongTopics.length > 0 ? `STUDENT'S STRONG AREAS: ${strongTopics.join(", ")} — Include some challenging problems here.` : ""}

═══ EXAMPLES OF GOOD QUESTIONS ═══

Fill-in-blank (word problem):
{"question": "A train travels at 60 km/h for 3 hours. How many kilometers does it cover?", "answer": "180", "topic": "multiplication"}

Fill-in-blank (with LaTeX):
{"question": "What is $\\frac{3}{4} + \\frac{1}{2}$?", "answer": "5/4", "topic": "fractions"}

Multiple-choice:
{"question": "A square has a perimeter of 36 cm. What is the length of each side?", "answer": "9", "topic": "geometry", "choices": ["6", "9", "12", "18"]}

Multiple-choice (with LaTeX):
{"question": "Which is the largest?", "answer": "$\\frac{3}{4}$", "topic": "fractions", "choices": ["$\\frac{1}{2}$", "$\\frac{3}{4}$", "$\\frac{2}{3}$", "$\\frac{1}{3}$"]}

═══ BAD QUESTIONS (AVOID) ═══
- "5 + 3 = ?" (too bare, no context)
- "12 × 4 = ?" (boring, repetitive)
- Same pattern repeated multiple times

═══ OUTPUT FORMAT ═══
Return ONLY a valid JSON array. No markdown, no code fences, no extra text.
For fill_in_blank: {"question": "...", "answer": "...", "topic": "..."}
For multiple_choice: {"question": "...", "answer": "...", "topic": "...", "choices": ["...", "...", "...", "..."]}

Answers must be numeric or simple fractions (e.g., "180", "3/4", "0.5"). For MCQ, the answer must exactly match one of the choices.`;

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
        (q: { question: string; answer: string; topic: string; choices?: string[] }, i: number) => ({
          id: `q${i + 1}`,
          type: q.choices ? "multiple_choice" : "fill_in_blank",
          question: q.question,
          correctAnswer: String(q.answer),
          topic: q.topic,
          ...(q.choices ? { choices: q.choices } : {}),
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
          ...(q.choices ? { choices: q.choices } : {}),
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
