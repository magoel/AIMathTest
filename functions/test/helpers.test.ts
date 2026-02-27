/**
 * Tests for helper logic extracted from generateTest.ts.
 *
 * We copy the small pure-function logic inline rather than importing from
 * the compiled source, because the source has Firebase dependencies that
 * would require extensive mocking in Jest.
 */

// ── Share code generation (lines 32-39 of generateTest.ts) ──────────────

function generateShareCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 5; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return `MATH-${code}`;
}

// ── LaTeX escaping (line 258 of generateTest.ts) ────────────────────────

function escapeLatex(jsonStr: string): string {
  return jsonStr.replace(/\\([a-zA-Z])/g, "\\\\$1");
}

// ── JSON code fence stripping (lines 245-249 of generateTest.ts) ────────

function stripCodeFences(text: string): string {
  let jsonStr = text.trim();
  if (jsonStr.startsWith("```")) {
    jsonStr = jsonStr
      .replace(/^```(?:json)?\n?/, "")
      .replace(/\n?```$/, "");
  }
  return jsonStr;
}

// ═════════════════════════════════════════════════════════════════════════
// Tests
// ═════════════════════════════════════════════════════════════════════════

describe("generateShareCode", () => {
  it("returns a string prefixed with MATH-", () => {
    const code = generateShareCode();
    expect(code.startsWith("MATH-")).toBe(true);
  });

  it("has exactly 10 characters total (MATH- plus 5 random chars)", () => {
    const code = generateShareCode();
    expect(code).toHaveLength(10);
  });

  it("matches the expected format /^MATH-[A-HJ-NP-Z2-9]{5}$/", () => {
    // Run several times to increase confidence
    for (let i = 0; i < 100; i++) {
      const code = generateShareCode();
      expect(code).toMatch(/^MATH-[A-HJ-NP-Z2-9]{5}$/);
    }
  });

  it("never contains confusing characters I, O, 0, or 1", () => {
    for (let i = 0; i < 200; i++) {
      const code = generateShareCode();
      const suffix = code.slice(5); // the 5 random chars
      expect(suffix).not.toMatch(/[IO01]/);
    }
  });

  it("generates varied codes (not all identical)", () => {
    const codes = new Set<string>();
    for (let i = 0; i < 20; i++) {
      codes.add(generateShareCode());
    }
    // With 30^5 ≈ 24 million possibilities, 20 draws should all be unique
    expect(codes.size).toBeGreaterThan(1);
  });

  it("uses only characters from the defined character set", () => {
    const allowedChars = new Set("ABCDEFGHJKLMNPQRSTUVWXYZ23456789".split(""));
    for (let i = 0; i < 50; i++) {
      const suffix = generateShareCode().slice(5);
      for (const ch of suffix) {
        expect(allowedChars.has(ch)).toBe(true);
      }
    }
  });
});

describe("escapeLatex", () => {
  it("doubles backslash before \\frac", () => {
    expect(escapeLatex("\\frac{1}{2}")).toBe("\\\\frac{1}{2}");
  });

  it("doubles backslash before \\times", () => {
    expect(escapeLatex("5 \\times 3")).toBe("5 \\\\times 3");
  });

  it("doubles backslash before \\sqrt", () => {
    expect(escapeLatex("\\sqrt{16}")).toBe("\\\\sqrt{16}");
  });

  it("doubles backslash before \\theta and \\pi", () => {
    const input = "\\theta + \\pi";
    const expected = "\\\\theta + \\\\pi";
    expect(escapeLatex(input)).toBe(expected);
  });

  it("handles multiple LaTeX commands in one string", () => {
    const input = "\\frac{\\sqrt{2}}{\\pi}";
    const expected = "\\\\frac{\\\\sqrt{2}}{\\\\pi}";
    expect(escapeLatex(input)).toBe(expected);
  });

  it("does NOT escape non-letter backslash sequences like \\{", () => {
    // \\{ has a brace after the backslash, not a letter — should be untouched
    expect(escapeLatex("\\{x\\}")).toBe("\\{x\\}");
  });

  it("escapes the second backslash-letter even after another backslash", () => {
    // JS literal "line1\\\\line2" → actual chars: line1 \ \ l i n e 2
    // The regex matches the 2nd backslash + 'l' as \l → doubles it to \\l
    // Result actual chars: line1 \ \ \ l i n e 2
    // As JS literal: "line1\\\\\\line2"
    expect(escapeLatex("line1\\\\line2")).toBe("line1\\\\\\line2");
  });

  it("does NOT alter strings without backslashes", () => {
    const plain = "Just a plain string with no backslashes";
    expect(escapeLatex(plain)).toBe(plain);
  });

  it("handles empty string", () => {
    expect(escapeLatex("")).toBe("");
  });

  it("escapes both upper and lower case letters after backslash", () => {
    expect(escapeLatex("\\Alpha \\beta")).toBe("\\\\Alpha \\\\beta");
  });
});

describe("stripCodeFences", () => {
  it("strips ```json fences from wrapped JSON", () => {
    const input = '```json\n[{"question":"test"}]\n```';
    expect(stripCodeFences(input)).toBe('[{"question":"test"}]');
  });

  it("strips plain ``` fences (no language tag)", () => {
    const input = '```\n[{"question":"test"}]\n```';
    expect(stripCodeFences(input)).toBe('[{"question":"test"}]');
  });

  it("leaves plain JSON unchanged (no fences)", () => {
    const input = '[{"question":"test"}]';
    expect(stripCodeFences(input)).toBe('[{"question":"test"}]');
  });

  it("trims leading/trailing whitespace even without fences", () => {
    const input = '  [{"question":"test"}]  ';
    expect(stripCodeFences(input)).toBe('[{"question":"test"}]');
  });

  it("handles ```json without trailing newline before content", () => {
    const input = '```json[{"q":"x"}]\n```';
    expect(stripCodeFences(input)).toBe('[{"q":"x"}]');
  });

  it("handles multi-line JSON inside fences", () => {
    const input = '```json\n[\n  {"a": 1},\n  {"b": 2}\n]\n```';
    const expected = '[\n  {"a": 1},\n  {"b": 2}\n]';
    expect(stripCodeFences(input)).toBe(expected);
  });

  it("does NOT strip fences that are not at the start", () => {
    // If content doesn't start with ```, the regex won't match
    const input = 'Some text ```json\n[]\n```';
    expect(stripCodeFences(input)).toBe(input.trim());
  });
});
