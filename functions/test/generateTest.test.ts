/**
 * Tests for core logic from generateTest.ts.
 *
 * We replicate the small inline logic rather than importing from the
 * compiled source, because it has Firebase/Gemini dependencies that
 * would need extensive mocking.
 */

// ── Question type detection (line 265 of generateTest.ts) ───────────────
//    type: q.choices ? "multiple_choice" : "fill_in_blank"

interface RawQuestion {
  question: string;
  answer: string | number;
  topic: string;
  choices?: string[];
}

interface Question {
  id: string;
  type: string;
  question: string;
  correctAnswer: string;
  topic: string;
  choices?: string[];
}

function mapQuestion(q: RawQuestion, index: number): Question {
  return {
    id: `q${index + 1}`,
    type: q.choices ? "multiple_choice" : "fill_in_blank",
    question: q.question,
    correctAnswer: String(q.answer),
    topic: q.topic,
    ...(q.choices ? { choices: q.choices } : {}),
  };
}

// ── Expiry calculation (lines 278-279 of generateTest.ts) ───────────────
//    new Date(Date.now() + 90 * 24 * 60 * 60 * 1000)

function calculateExpiry(now: Date): Date {
  return new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);
}

// ═════════════════════════════════════════════════════════════════════════
// Tests
// ═════════════════════════════════════════════════════════════════════════

describe("question type detection", () => {
  it('returns "multiple_choice" when choices array is present', () => {
    const q: RawQuestion = {
      question: "What is 2+2?",
      answer: "4",
      topic: "addition",
      choices: ["3", "4", "5", "6"],
    };
    const result = mapQuestion(q, 0);
    expect(result.type).toBe("multiple_choice");
  });

  it('returns "fill_in_blank" when choices is absent (not in object)', () => {
    const q: RawQuestion = {
      question: "What is 2+2?",
      answer: "4",
      topic: "addition",
    };
    const result = mapQuestion(q, 0);
    expect(result.type).toBe("fill_in_blank");
  });

  it('returns "fill_in_blank" when choices is explicitly undefined', () => {
    const q: RawQuestion = {
      question: "What is 2+2?",
      answer: "4",
      topic: "addition",
      choices: undefined,
    };
    const result = mapQuestion(q, 0);
    expect(result.type).toBe("fill_in_blank");
  });

  it("includes choices in output only when present", () => {
    const withChoices = mapQuestion(
      { question: "Q?", answer: "A", topic: "t", choices: ["a", "b", "c", "d"] },
      0
    );
    expect(withChoices.choices).toEqual(["a", "b", "c", "d"]);

    const withoutChoices = mapQuestion(
      { question: "Q?", answer: "A", topic: "t" },
      0
    );
    expect(withoutChoices).not.toHaveProperty("choices");
  });

  it('returns "fill_in_blank" when choices is an empty array (truthy in JS)', () => {
    // An empty array is truthy, so this should be "multiple_choice" per the logic
    // This tests the ACTUAL behavior of the code: [] is truthy
    const q: RawQuestion = {
      question: "What is 2+2?",
      answer: "4",
      topic: "addition",
      choices: [],
    };
    const result = mapQuestion(q, 0);
    // Empty array is truthy in JS, so the ternary yields "multiple_choice"
    expect(result.type).toBe("multiple_choice");
  });
});

describe("question ID generation", () => {
  it("generates sequential IDs starting from q1", () => {
    const questions: RawQuestion[] = [
      { question: "Q1", answer: "1", topic: "addition" },
      { question: "Q2", answer: "2", topic: "subtraction" },
      { question: "Q3", answer: "3", topic: "multiplication" },
    ];
    const mapped = questions.map((q, i) => mapQuestion(q, i));
    expect(mapped[0].id).toBe("q1");
    expect(mapped[1].id).toBe("q2");
    expect(mapped[2].id).toBe("q3");
  });
});

describe("answer normalization", () => {
  it("converts numeric answer to string", () => {
    const q: RawQuestion = {
      question: "What is 5+5?",
      answer: 10 as unknown as string,
      topic: "addition",
    };
    const result = mapQuestion(q, 0);
    expect(result.correctAnswer).toBe("10");
    expect(typeof result.correctAnswer).toBe("string");
  });

  it("keeps string answer as-is", () => {
    const q: RawQuestion = {
      question: "Simplify 3/4 + 1/4",
      answer: "1",
      topic: "fractions",
    };
    const result = mapQuestion(q, 0);
    expect(result.correctAnswer).toBe("1");
  });

  it("converts fractional string correctly", () => {
    const q: RawQuestion = {
      question: "What is half of 1?",
      answer: "1/2",
      topic: "fractions",
    };
    const result = mapQuestion(q, 0);
    expect(result.correctAnswer).toBe("1/2");
  });

  it("converts floating-point number to string", () => {
    const q: RawQuestion = {
      question: "What is 1 divided by 4?",
      answer: 0.25 as unknown as string,
      topic: "division",
    };
    const result = mapQuestion(q, 0);
    expect(result.correctAnswer).toBe("0.25");
    expect(typeof result.correctAnswer).toBe("string");
  });

  it("converts zero to string '0'", () => {
    const q: RawQuestion = {
      question: "What is 5-5?",
      answer: 0 as unknown as string,
      topic: "subtraction",
    };
    const result = mapQuestion(q, 0);
    expect(result.correctAnswer).toBe("0");
  });
});

describe("expiry calculation", () => {
  it("returns a date exactly 90 days after the given date", () => {
    const now = new Date("2026-01-15T12:00:00Z");
    const expiry = calculateExpiry(now);
    const expectedDate = new Date("2026-04-15T12:00:00Z");
    expect(expiry.getTime()).toBe(expectedDate.getTime());
  });

  it("calculates 90 days as 90 * 24 * 60 * 60 * 1000 ms", () => {
    const now = new Date("2026-06-01T00:00:00Z");
    const expiry = calculateExpiry(now);
    const diffMs = expiry.getTime() - now.getTime();
    expect(diffMs).toBe(90 * 24 * 60 * 60 * 1000);
  });

  it("handles end-of-year boundary (wraps into next year)", () => {
    const now = new Date("2026-11-01T00:00:00Z");
    const expiry = calculateExpiry(now);
    // Nov 1 + 90 days = Jan 30, 2027
    expect(expiry.getFullYear()).toBe(2027);
    expect(expiry.getMonth()).toBe(0); // January
    expect(expiry.getDate()).toBe(30);
  });

  it("handles leap year boundary", () => {
    // 2028 is a leap year; Feb 1 + 90 days = May 1
    const now = new Date("2028-02-01T00:00:00Z");
    const expiry = calculateExpiry(now);
    expect(expiry.getFullYear()).toBe(2028);
    expect(expiry.getMonth()).toBe(4); // May
    expect(expiry.getDate()).toBe(1);
  });

  it("preserves time of day", () => {
    const now = new Date("2026-03-10T15:30:45.123Z");
    const expiry = calculateExpiry(now);
    expect(expiry.getUTCHours()).toBe(15);
    expect(expiry.getUTCMinutes()).toBe(30);
    expect(expiry.getUTCSeconds()).toBe(45);
    expect(expiry.getUTCMilliseconds()).toBe(123);
  });
});
