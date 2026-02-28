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
  { secrets: [geminiApiKey], timeoutSeconds: 120 },
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

═══ SUB-TOPICS — VARY WITHIN EACH TOPIC (MANDATORY) ═══
For each selected topic, cover DIFFERENT sub-topics across questions. Do NOT repeat the same sub-topic.
- addition/subtraction/multiplication/division: word problems, multi-digit, estimation, mental math
- fractions: addition, subtraction, multiplication, comparison, mixed numbers, simplification
- decimals: operations, conversion from fractions, place value, rounding
- percentages: finding percentage, percentage increase/decrease, discount, profit & loss
- algebra: linear equations, quadratic equations, polynomials, factorization, inequalities, sequences & series, simultaneous equations
- geometry: area, perimeter, volume, surface area, angles, triangles, circles, coordinate geometry, Pythagoras
- trigonometry: sin/cos/tan ratios, identities ($\\sin^2\\theta + \\cos^2\\theta = 1$), trigonometric equations, inverse trig, heights & distances, graphs of trig functions
- calculus: differentiation (power rule, chain rule, product rule), integration (definite & indefinite), limits, area under curve, maxima/minima
- number_systems: real numbers, surds & rationalization, prime factorization, HCF/LCM, irrational numbers
- probability: basic probability, complementary events, independent events, conditional probability, combinations/permutations
- data_handling: mean/median/mode, range, frequency distribution, bar/pie charts, interpretation
- ratio_proportion: direct/inverse proportion, unitary method, speed-distance-time, work problems
- measurement: unit conversion, area/volume of real objects, time calculations
- word_problems: multi-step, real-world scenarios, mixed operations

═══ QUESTION VARIETY (MANDATORY) ═══
- At least 40% must be WORD PROBLEMS with real-world context (shopping, travel, cooking, sports, etc.)
- No more than 30% should be bare arithmetic like "X + Y = ?"
- Include multi-step problems, pattern recognition, and applied math
- Make questions age-appropriate and engaging for ${gradeLabel} students

═══ QUESTION TYPES ═══
- "fill_in_blank" (${fibCount} questions): Student types a numeric answer. Good for computation and short answers.
- "multiple_choice" (${mcqCount} questions): Student picks from exactly 4 options. Good for conceptual questions, estimation, word problems. Include a "choices" array with 4 options. CRITICAL: Exactly ONE choice must be the correct answer. The other 3 must be clearly wrong (plausible distractors, but unambiguously incorrect). Never generate MCQs where multiple choices could be considered correct.

═══ MATH NOTATION (MANDATORY) ═══
ALWAYS wrap ALL mathematical expressions in LaTeX dollar signs. This is critical for rendering.
- Fractions: ALWAYS use $\\frac{2}{3}$ (never write "2/3" in questions)
- Exponents: $x^2$, $3^4$, $2^{10}$
- Square roots: $\\sqrt{16}$, $\\sqrt{25}$
- Multiplication: $24 \\times 15$
- Division: $144 \\div 12$
- Variables and equations: $x + 5 = 12$, $2x - 3 = 7$
- Mixed numbers: $2\\frac{1}{2}$
- Comparisons: $\\frac{3}{4} > \\frac{1}{2}$
- Even simple expressions in questions: "$5 + 3$" not "5 + 3"
- Numbers in word problems can stay as plain text: "Riya has 8 apples"
- Answers should be plain text/numbers (e.g., "180", "5/4") — NOT LaTeX
- MCQ choices that contain math MUST use LaTeX: "$\\frac{3}{4}$" not "3/4"

═══ DIFFICULTY SCALING (${difficulty}/10) — EACH LEVEL IS TWICE AS HARD ═══
The difficulty MUST increase exponentially. Level 5 should be noticeably harder than level 4. Level 10 should feel nearly impossible for most students.

Level 1: Trivial single-step, single-digit numbers. "What is $3 + 2$?"
Level 2: Single-step, double-digit numbers. "What is $15 + 28$?"
Level 3: Single-step word problems with small numbers. "Riya has 8 apples. She gives 3 away. How many left?"
Level 4: Two-step problems, moderate numbers. "A shop sells pens for ₹12 each. Priya buys 5 pens and 3 notebooks at ₹25 each. How much does she spend?"
Level 5: Multi-step with mixed operations, requires planning. "A train covers 240 km in 4 hours. Another train covers 180 km in 3 hours. How much faster is the second train in km/h?"
Level 6: Problems requiring conceptual understanding, not just computation. "If $\\frac{2}{5}$ of a number is 30, what is $\\frac{3}{4}$ of the same number?"
Level 7: Complex multi-concept problems. "A cylindrical tank of radius 7 cm and height 10 cm is filled with water. If the water is poured into a rectangular box of length 22 cm and width 10 cm, what is the height of water?"
Level 8: Problems requiring insight or non-obvious approach. "The sum of three consecutive odd numbers is 75. What is the product of the smallest and largest of these numbers?"
Level 9: Olympiad-style problems requiring creative thinking. "How many 3-digit numbers are there where the sum of the digits equals 25?"
Level 10: Competition math — requires multiple insights, elegant reasoning. "Find all integer solutions to $x^2 - y^2 = 2025$ where $x > y > 0$."

IMPORTANT: You are generating for difficulty ${difficulty}/10. Make sure ALL questions match this difficulty level. Do NOT generate easy questions at high difficulty levels.

═══ BOARD-SPECIFIC STYLE ═══
${boardLabel === "CBSE" ? "Use Indian context (₹ currency, Indian names like Riya/Amit/Priya, Indian units, NCERT-style phrasing)" : ""}
${boardLabel.includes("IB") ? "Use inquiry-based framing, international context, encourage mathematical thinking" : ""}
${boardLabel.includes("Cambridge") ? "Use British English, precise mathematical language, structured problem format" : ""}

${weakTopics.length > 0 ? `\nSTUDENT'S WEAK AREAS: ${weakTopics.join(", ")} — Include 30% problems targeting these.` : ""}
${strongTopics.length > 0 ? `STUDENT'S STRONG AREAS: ${strongTopics.join(", ")} — Include some challenging problems here.` : ""}

═══ EXAMPLES OF GOOD QUESTIONS ═══

Fill-in-blank (word problem):
{"question": "A train travels at 60 km/h for 3 hours. How many kilometers does it cover?", "answer": "180", "topic": "multiplication"}

Fill-in-blank (computation with LaTeX):
{"question": "Calculate: $\\frac{3}{4} + \\frac{1}{2}$", "answer": "5/4", "topic": "fractions"}

Fill-in-blank (algebra with LaTeX):
{"question": "Solve: $2x + 5 = 17$. Find $x$.", "answer": "6", "topic": "algebra"}

Fill-in-blank (arithmetic with LaTeX):
{"question": "What is $125 \\times 8$?", "answer": "1000", "topic": "multiplication"}

Multiple-choice (word problem):
{"question": "A rectangle has length 12 cm and width 8 cm. What is its area?", "answer": "96", "topic": "geometry", "choices": ["80", "96", "40", "120"]}

Multiple-choice (with LaTeX):
{"question": "Which fraction is the largest?", "answer": "$\\frac{3}{4}$", "topic": "fractions", "choices": ["$\\frac{1}{2}$", "$\\frac{3}{4}$", "$\\frac{2}{3}$", "$\\frac{1}{3}$"]}

Multiple-choice (roots with LaTeX):
{"question": "What is the value of $\\sqrt{144}$?", "answer": "12", "topic": "number_systems", "choices": ["11", "12", "13", "14"]}

═══ BAD QUESTIONS (AVOID) ═══
- "5 + 3 = ?" (too bare, no context, no LaTeX)
- "What is 3/4 + 1/2?" (fractions not in LaTeX — MUST use $\\frac{3}{4} + \\frac{1}{2}$)
- "12 × 4 = ?" (boring, and should be $12 \\times 4$)
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
        model: "gemini-2.5-flash",
        generationConfig: {
          responseMimeType: "application/json",
        },
      });

      // Retry with longer backoff for rate limit errors (429, 503)
      const retryDelays = [5000, 15000, 30000]; // 5s, 15s, 30s
      let text = "";
      for (let attempt = 0; attempt <= retryDelays.length; attempt++) {
        try {
          const result = await model.generateContent(prompt);
          text = result.response.text();
          break;
        } catch (retryErr: unknown) {
          const msg = retryErr instanceof Error ? retryErr.message : String(retryErr);
          if ((msg.includes("429") || msg.includes("503")) && attempt < retryDelays.length) {
            const delay = retryDelays[attempt];
            console.log(`Gemini API rate limited (attempt ${attempt + 1}/${retryDelays.length + 1}), retrying in ${delay / 1000}s...`);
            await new Promise((r) => setTimeout(r, delay));
            continue;
          }
          // Give a friendlier error for rate limits
          if (msg.includes("429")) {
            throw new Error("AI service is busy. Please wait a moment and try again.");
          }
          throw retryErr;
        }
      }

      // Parse response
      let jsonStr = text.trim();
      if (jsonStr.startsWith("```")) {
        jsonStr = jsonStr
          .replace(/^```(?:json)?\n?/, "")
          .replace(/\n?```$/, "");
      }

      // Fix LaTeX backslashes BEFORE JSON.parse().
      // The AI may output \frac, \sqrt, \times, \theta etc. with single
      // backslashes inside JSON strings. Characters like \f, \b, \t are
      // valid JSON escapes that would be misinterpreted by JSON.parse().
      // Solution: double-escape ALL \letter sequences AND \non-letter
      // LaTeX sequences (like \, \; \! \{ \}) so JSON.parse()
      // preserves the backslash as a literal character.
      // Step 1: \letter (e.g., \frac, \times, \theta)
      jsonStr = jsonStr.replace(/\\([a-zA-Z])/g, "\\\\$1");
      // Step 2: \non-letter that aren't valid JSON escapes (\, \; \! \{ \} etc.)
      // Excludes: \" \\ \/ (valid JSON escapes) and letters (already handled)
      jsonStr = jsonStr.replace(/\\([^"a-zA-Z\\\\/])/g, "\\\\$1");

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

      // ═══ ANSWER VERIFICATION STEP ═══
      // Send questions back to Gemini to verify mathematical correctness.
      // This catches LLM hallucinations (e.g., saying 1/4 < 1/5).
      const verifyPrompt = `You are a math answer verification expert. Check each question and its marked correct answer for mathematical accuracy.

For each question, verify the answer is MATHEMATICALLY CORRECT. For MCQs, verify the correct answer is actually the right choice among the options.

Questions to verify:
${JSON.stringify(questions.map((q) => ({
  id: q.id,
  question: q.question,
  correctAnswer: q.correctAnswer,
  choices: q.choices || null,
})), null, 2)}

Return a JSON array with ONLY the corrections needed. If all answers are correct, return an empty array [].
Format for corrections: [{"id": "q3", "correctAnswer": "fixed_answer"}]

IMPORTANT:
- Only return corrections, not confirmations
- The corrected answer must exactly match one of the choices for MCQs
- For fill-in-blank, return the simplified numeric answer
- Return ONLY valid JSON, no markdown fences`;

      try {
        const verifyResult = await model.generateContent(verifyPrompt);
        let verifyText = verifyResult.response.text().trim();
        if (verifyText.startsWith("```")) {
          verifyText = verifyText
            .replace(/^```(?:json)?\n?/, "")
            .replace(/\n?```$/, "");
        }
        // Apply LaTeX escaping to verification response too
        verifyText = verifyText.replace(/\\([a-zA-Z])/g, "\\\\$1");
        verifyText = verifyText.replace(/\\([^"a-zA-Z\\\\/])/g, "\\\\$1");

        const corrections: { id: string; correctAnswer: string }[] = JSON.parse(verifyText);
        if (corrections.length > 0) {
          console.log(`Answer verification found ${corrections.length} correction(s):`, JSON.stringify(corrections));
          for (const fix of corrections) {
            const q = questions.find((q) => q.id === fix.id);
            if (q) {
              console.log(`  Fixing ${q.id}: "${q.correctAnswer}" → "${fix.correctAnswer}"`);
              q.correctAnswer = fix.correctAnswer;
            }
          }
        }
      } catch (verifyErr) {
        // Verification failed — proceed with original answers rather than blocking
        console.warn("Answer verification failed, using original answers:", verifyErr);
      }

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
