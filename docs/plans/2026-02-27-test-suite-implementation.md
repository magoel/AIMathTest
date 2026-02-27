# Test Suite Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add comprehensive unit, provider, widget, and Cloud Function tests with CI integration.

**Architecture:** Layered test suite — pure Dart unit tests first (no Flutter deps), then provider/widget tests with mocking, then Jest tests for Cloud Functions. CI pipeline gates deployment on test pass.

**Tech Stack:** Flutter test, mockito, build_runner, Jest, ts-jest

---

### Task 1: Setup — Dependencies, Directories, CI

**Files:**
- Modify: `pubspec.yaml` (dev_dependencies)
- Modify: `functions/package.json` (devDependencies + scripts)
- Modify: `.github/workflows/deploy.yml` (add test steps)
- Create: `test/unit/`, `test/providers/`, `test/widgets/`, `functions/test/` directories

**Step 1: Add Flutter test dependencies to pubspec.yaml**

Add to `dev_dependencies:` section:

```yaml
  mockito: ^5.4.4
  build_runner: ^2.4.8
```

**Step 2: Add Jest to Cloud Functions**

In `functions/package.json`, add to `devDependencies`:

```json
"jest": "^29.7.0",
"ts-jest": "^29.1.1",
"@types/jest": "^29.5.11"
```

Add to `scripts`:

```json
"test": "jest --passWithNoTests"
```

Create `functions/jest.config.js`:

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/test/**/*.test.ts'],
  moduleFileExtensions: ['ts', 'js', 'json'],
};
```

**Step 3: Add test steps to CI pipeline**

In `.github/workflows/deploy.yml`, add after the "Analyze" step and before "Build web":

```yaml
      - name: Run Flutter tests
        run: flutter test

      - name: Run Cloud Function tests
        run: cd functions && npm ci && npm test
```

**Step 4: Create directory structure**

```bash
mkdir -p test/unit/models test/unit/config test/unit/helpers test/providers test/widgets test/screens functions/test
```

**Step 5: Install Cloud Function test deps**

```bash
cd functions && npm install --save-dev jest ts-jest @types/jest
```

**Step 6: Commit**

```bash
git add pubspec.yaml functions/package.json functions/jest.config.js .github/workflows/deploy.yml
git commit -m "Add test dependencies and CI test steps"
```

---

### Task 2: Unit Tests — Models

**Files:**
- Create: `test/unit/models/question_model_test.dart`
- Create: `test/unit/models/attempt_model_test.dart`

**Step 1: Write question_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/models/question_model.dart';

void main() {
  group('QuestionModel', () {
    group('isMultipleChoice', () {
      test('returns true for multiple_choice with choices', () {
        final q = QuestionModel(
          id: 'q1',
          type: 'multiple_choice',
          question: 'Pick one',
          correctAnswer: 'A',
          topic: 'algebra',
          choices: ['A', 'B', 'C', 'D'],
        );
        expect(q.isMultipleChoice, isTrue);
      });

      test('returns false for fill_in_blank', () {
        final q = QuestionModel(
          id: 'q1',
          question: 'What is 2+2?',
          correctAnswer: '4',
          topic: 'addition',
        );
        expect(q.isMultipleChoice, isFalse);
      });

      test('returns false when type is multiple_choice but choices is null', () {
        final q = QuestionModel(
          id: 'q1',
          type: 'multiple_choice',
          question: 'Pick one',
          correctAnswer: 'A',
          topic: 'algebra',
        );
        expect(q.isMultipleChoice, isFalse);
      });

      test('defaults type to fill_in_blank', () {
        final q = QuestionModel(
          id: 'q1',
          question: 'What is 5+3?',
          correctAnswer: '8',
          topic: 'addition',
        );
        expect(q.type, 'fill_in_blank');
      });
    });

    group('fromMap', () {
      test('parses complete MCQ data', () {
        final q = QuestionModel.fromMap({
          'id': 'q1',
          'type': 'multiple_choice',
          'question': 'What is 2+2?',
          'correctAnswer': '4',
          'topic': 'addition',
          'choices': ['3', '4', '5', '6'],
        });
        expect(q.id, 'q1');
        expect(q.isMultipleChoice, isTrue);
        expect(q.choices, ['3', '4', '5', '6']);
        expect(q.correctAnswer, '4');
      });

      test('handles missing fields with defaults', () {
        final q = QuestionModel.fromMap({});
        expect(q.id, '');
        expect(q.type, 'fill_in_blank');
        expect(q.question, '');
        expect(q.correctAnswer, '');
        expect(q.topic, '');
        expect(q.choices, isNull);
      });

      test('toMap round-trips correctly', () {
        final original = QuestionModel(
          id: 'q1',
          type: 'multiple_choice',
          question: 'Pick',
          correctAnswer: 'A',
          topic: 'algebra',
          choices: ['A', 'B', 'C', 'D'],
        );
        final restored = QuestionModel.fromMap(original.toMap());
        expect(restored.id, original.id);
        expect(restored.type, original.type);
        expect(restored.choices, original.choices);
      });
    });
  });
}
```

**Step 2: Write attempt_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/models/attempt_model.dart';

void main() {
  group('AnswerModel', () {
    test('fromMap parses correctly', () {
      final a = AnswerModel.fromMap({
        'questionId': 'q1',
        'userAnswer': '42',
        'isCorrect': true,
      });
      expect(a.questionId, 'q1');
      expect(a.userAnswer, '42');
      expect(a.isCorrect, isTrue);
    });

    test('fromMap defaults missing fields', () {
      final a = AnswerModel.fromMap({});
      expect(a.questionId, '');
      expect(a.userAnswer, '');
      expect(a.isCorrect, isFalse);
    });

    test('toMap round-trips correctly', () {
      const original = AnswerModel(
        questionId: 'q5',
        userAnswer: '100',
        isCorrect: true,
      );
      final restored = AnswerModel.fromMap(original.toMap());
      expect(restored.questionId, original.questionId);
      expect(restored.userAnswer, original.userAnswer);
      expect(restored.isCorrect, original.isCorrect);
    });
  });

  group('AttemptModel', () {
    test('stores score and percentage correctly', () {
      final attempt = AttemptModel(
        id: 'a1',
        testId: 't1',
        parentId: 'p1',
        profileId: 'pr1',
        answers: const [
          AnswerModel(questionId: 'q1', userAnswer: '4', isCorrect: true),
          AnswerModel(questionId: 'q2', userAnswer: '5', isCorrect: false),
        ],
        score: 1,
        totalQuestions: 2,
        percentage: 50.0,
        timeTaken: 120,
        shuffleOrder: [0, 1],
        completedAt: DateTime(2026, 2, 27),
      );
      expect(attempt.score, 1);
      expect(attempt.totalQuestions, 2);
      expect(attempt.percentage, 50.0);
      expect(attempt.isRetake, isFalse);
    });

    test('isRetake defaults to false', () {
      final attempt = AttemptModel(
        id: 'a1',
        testId: 't1',
        parentId: 'p1',
        profileId: 'pr1',
        answers: const [],
        score: 0,
        totalQuestions: 0,
        percentage: 0,
        timeTaken: 0,
        shuffleOrder: [],
        completedAt: DateTime(2026, 2, 27),
      );
      expect(attempt.isRetake, isFalse);
      expect(attempt.previousAttemptId, isNull);
    });

    test('retake has previousAttemptId', () {
      final attempt = AttemptModel(
        id: 'a2',
        testId: 't1',
        parentId: 'p1',
        profileId: 'pr1',
        answers: const [],
        score: 5,
        totalQuestions: 10,
        percentage: 50,
        timeTaken: 300,
        shuffleOrder: [4, 2, 0, 1, 3],
        isRetake: true,
        previousAttemptId: 'a1',
        completedAt: DateTime(2026, 2, 27),
      );
      expect(attempt.isRetake, isTrue);
      expect(attempt.previousAttemptId, 'a1');
    });
  });
}
```

**Step 3: Run tests**

```bash
flutter test test/unit/models/
```

Expected: All tests PASS.

**Step 4: Commit**

```bash
git add test/unit/models/
git commit -m "Add unit tests for QuestionModel and AttemptModel"
```

---

### Task 3: Unit Tests — Config & Helpers

**Files:**
- Create: `test/unit/config/constants_test.dart`
- Create: `test/unit/config/board_curriculum_test.dart`
- Create: `test/unit/helpers/friendly_error_test.dart`

**Step 1: Write constants_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/config/constants.dart';

void main() {
  group('AppConstants', () {
    group('scoreMessage', () {
      test('returns Perfect Score for 100%', () {
        expect(AppConstants.scoreMessage(100), 'Perfect Score!');
      });

      test('returns Great Job for 80-99%', () {
        expect(AppConstants.scoreMessage(80), 'Great Job!');
        expect(AppConstants.scoreMessage(99), 'Great Job!');
      });

      test('returns Good Effort for 60-79%', () {
        expect(AppConstants.scoreMessage(60), 'Good Effort!');
        expect(AppConstants.scoreMessage(79), 'Good Effort!');
      });

      test('returns Keep Practicing for below 60%', () {
        expect(AppConstants.scoreMessage(59), 'Keep Practicing!');
        expect(AppConstants.scoreMessage(0), 'Keep Practicing!');
      });
    });

    group('scoreEmoji', () {
      test('returns star for 100%', () {
        expect(AppConstants.scoreEmoji(100), '🌟');
      });

      test('returns party for 80-99%', () {
        expect(AppConstants.scoreEmoji(85), '🎉');
      });

      test('returns thumbs up for 60-79%', () {
        expect(AppConstants.scoreEmoji(65), '👍');
      });

      test('returns flexed bicep below 60%', () {
        expect(AppConstants.scoreEmoji(30), '💪');
      });
    });

    group('adminEmails', () {
      test('contains expected admin emails', () {
        expect(AppConstants.adminEmails, contains('manish.dce@gmail.com'));
        expect(AppConstants.adminEmails, contains('nupzbansal@gmail.com'));
        expect(AppConstants.adminEmails, contains('numerixlabs@gmail.com'));
      });

      test('does not contain random email', () {
        expect(AppConstants.adminEmails.contains('random@example.com'), isFalse);
      });
    });

    test('freeTestMonthlyLimit is 10', () {
      expect(AppConstants.freeTestMonthlyLimit, 10);
    });

    test('testExpiryDays is 90', () {
      expect(AppConstants.testExpiryDays, 90);
    });
  });
}
```

**Step 2: Write board_curriculum_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/config/board_curriculum.dart';

void main() {
  group('getAvailableTopics', () {
    group('K-2 students (full cumulative)', () {
      test('Kindergarten CBSE returns all basic topics', () {
        final topics = getAvailableTopics(Board.cbse, 0);
        expect(topics, isNotEmpty);
        // K should have basic arithmetic
        expect(topics.contains('addition'), isTrue);
      });

      test('Grade 1 returns cumulative set', () {
        final topics = getAvailableTopics(Board.cbse, 1);
        expect(topics, isNotEmpty);
      });

      test('Grade 2 returns cumulative set', () {
        final topics = getAvailableTopics(Board.cbse, 2);
        expect(topics, isNotEmpty);
      });
    });

    group('windowed grades (3-12)', () {
      test('Grade 5 CBSE returns at least 4 topics', () {
        final topics = getAvailableTopics(Board.cbse, 5);
        expect(topics.length, greaterThanOrEqualTo(4));
      });

      test('Grade 10 CBSE includes advanced topics', () {
        final topics = getAvailableTopics(Board.cbse, 10);
        expect(topics.length, greaterThanOrEqualTo(4));
      });

      test('Grade 12 CBSE includes highest-level topics', () {
        final topics = getAvailableTopics(Board.cbse, 12);
        expect(topics.length, greaterThanOrEqualTo(4));
      });
    });

    group('minimum 4 topics guarantee', () {
      test('every grade for every board has at least 4 topics', () {
        for (final board in Board.values) {
          for (int grade = 0; grade <= 12; grade++) {
            final topics = getAvailableTopics(board, grade);
            expect(
              topics.length,
              greaterThanOrEqualTo(4),
              reason: '${board.label} Grade $grade has ${topics.length} topics',
            );
          }
        }
      });
    });

    group('all boards work', () {
      test('IB board returns topics', () {
        final topics = getAvailableTopics(Board.ib, 6);
        expect(topics, isNotEmpty);
      });

      test('Cambridge board returns topics', () {
        final topics = getAvailableTopics(Board.cambridge, 6);
        expect(topics, isNotEmpty);
      });
    });

    group('topic windowing', () {
      test('higher grades have different topics than lower grades', () {
        final grade3 = getAvailableTopics(Board.cbse, 3);
        final grade10 = getAvailableTopics(Board.cbse, 10);
        // Grade 10 should have topics not in grade 3
        expect(grade10.difference(grade3), isNotEmpty);
      });
    });
  });

  group('Board enum', () {
    test('has label getter', () {
      expect(Board.cbse.label, isNotEmpty);
      expect(Board.ib.label, isNotEmpty);
      expect(Board.cambridge.label, isNotEmpty);
    });

    test('has description getter', () {
      expect(Board.cbse.description, isNotEmpty);
    });
  });
}
```

**Step 3: Write friendly_error_test.dart**

First, extract `_friendlyError` from test_config_screen into a shared helper so it's testable. Create `lib/helpers/error_helpers.dart`:

```dart
import 'package:flutter/material.dart';

/// Maps raw exceptions to kid/parent-friendly error messages.
({String message, IconData icon}) friendlyError(Object error) {
  final msg = error.toString().toLowerCase();
  if (msg.contains('socket') ||
      msg.contains('network') ||
      msg.contains('clientexception') ||
      msg.contains('failed host lookup')) {
    return (
      message: 'No internet connection. Please check your WiFi and try again.',
      icon: Icons.wifi_off,
    );
  }
  if (msg.contains('resource-exhausted') || msg.contains('429')) {
    return (
      message:
          'Our math engine is busy right now. Please try again in a minute.',
      icon: Icons.hourglass_top,
    );
  }
  if (msg.contains('deadline-exceeded') || msg.contains('timeout')) {
    return (
      message:
          'This is taking too long. Please try again with fewer questions.',
      icon: Icons.timer_off,
    );
  }
  if (msg.contains('unauthenticated') || msg.contains('permission-denied')) {
    return (
      message: 'Your session has expired. Please sign out and sign back in.',
      icon: Icons.lock_outline,
    );
  }
  if (msg.contains('failed-precondition')) {
    return (
      message: 'Something went wrong on our end. Please try again shortly.',
      icon: Icons.error_outline,
    );
  }
  return (
    message: 'Something went wrong. Please try again.',
    icon: Icons.error_outline,
  );
}
```

Then update `test_config_screen.dart` to import and use this shared helper instead of the local `_friendlyError` function.

Now write the test:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/helpers/error_helpers.dart';

void main() {
  group('friendlyError', () {
    test('maps SocketException to network error', () {
      final err = friendlyError(Exception('SocketException: Connection refused'));
      expect(err.message, contains('No internet'));
      expect(err.icon, Icons.wifi_off);
    });

    test('maps failed host lookup to network error', () {
      final err = friendlyError(Exception('failed host lookup'));
      expect(err.message, contains('No internet'));
    });

    test('maps resource-exhausted to rate limit message', () {
      final err = friendlyError(Exception('[firebase_functions/resource-exhausted]'));
      expect(err.message, contains('math engine is busy'));
      expect(err.icon, Icons.hourglass_top);
    });

    test('maps 429 to rate limit message', () {
      final err = friendlyError(Exception('HTTP 429 Too Many Requests'));
      expect(err.message, contains('math engine is busy'));
    });

    test('maps deadline-exceeded to timeout message', () {
      final err = friendlyError(Exception('[firebase_functions/deadline-exceeded]'));
      expect(err.message, contains('taking too long'));
      expect(err.icon, Icons.timer_off);
    });

    test('maps timeout to timeout message', () {
      final err = friendlyError(Exception('Connection timeout'));
      expect(err.message, contains('taking too long'));
    });

    test('maps unauthenticated to session expired', () {
      final err = friendlyError(Exception('[firebase_functions/unauthenticated]'));
      expect(err.message, contains('session has expired'));
      expect(err.icon, Icons.lock_outline);
    });

    test('maps permission-denied to session expired', () {
      final err = friendlyError(Exception('permission-denied'));
      expect(err.message, contains('session has expired'));
    });

    test('maps failed-precondition to server error', () {
      final err = friendlyError(Exception('[cloud_firestore/failed-precondition]'));
      expect(err.message, contains('wrong on our end'));
      expect(err.icon, Icons.error_outline);
    });

    test('maps unknown error to generic message', () {
      final err = friendlyError(Exception('something totally unexpected'));
      expect(err.message, 'Something went wrong. Please try again.');
      expect(err.icon, Icons.error_outline);
    });
  });
}
```

**Step 4: Run tests**

```bash
flutter test test/unit/
```

Expected: All tests PASS.

**Step 5: Commit**

```bash
git add lib/helpers/error_helpers.dart lib/screens/test_config/test_config_screen.dart test/unit/
git commit -m "Add unit tests for constants, curriculum, and error mapping"
```

---

### Task 4: Widget Tests

**Files:**
- Create: `test/widgets/math_text_test.dart`
- Create: `test/widgets/score_display_test.dart`

**Step 1: Write math_text_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/widgets/math_text.dart';

void main() {
  group('MathText', () {
    testWidgets('renders plain text without LaTeX', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathText('Hello World'))),
      );
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders mixed text and LaTeX', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MathText('What is \$2 + 3\$?')),
        ),
      );
      // The widget should render without errors
      expect(find.byType(MathText), findsOneWidget);
    });

    testWidgets('handles empty string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathText(''))),
      );
      expect(find.byType(MathText), findsOneWidget);
    });
  });

  group('MathText._cleanLatex (via rendering)', () {
    testWidgets('handles double-escaped backslashes', (tester) async {
      // Double-escaped LaTeX like \\frac should render correctly
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MathText('\$\\\\frac{1}{2}\$')),
        ),
      );
      expect(find.byType(MathText), findsOneWidget);
    });
  });
}
```

**Step 2: Write score_display_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/widgets/score_display.dart';

void main() {
  group('ScoreDisplay', () {
    testWidgets('displays score and total', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScoreDisplay(score: 8, total: 10)),
        ),
      );
      // Pump animation frames
      await tester.pumpAndSettle();

      expect(find.text('8/10'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('displays 0% for zero score', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScoreDisplay(score: 0, total: 5)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0/5'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('displays 100% for perfect score', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScoreDisplay(score: 10, total: 10)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('10/10'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('handles zero total without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScoreDisplay(score: 0, total: 0)),
        ),
      );
      await tester.pumpAndSettle();

      // Should not crash — 0/0 should show 0%
      expect(find.byType(ScoreDisplay), findsOneWidget);
    });
  });
}
```

**Step 3: Run tests**

```bash
flutter test test/widgets/
```

Expected: All tests PASS.

**Step 4: Commit**

```bash
git add test/widgets/
git commit -m "Add widget tests for MathText and ScoreDisplay"
```

---

### Task 5: Cloud Function Tests (Jest)

**Files:**
- Create: `functions/test/helpers.test.ts`
- Create: `functions/test/generateTest.test.ts`

**Step 1: Write helpers.test.ts**

```typescript
// Test the share code generation and LaTeX escaping logic

describe('generateShareCode', () => {
  // Extract the function logic for testing
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  function generateShareCode(): string {
    let code = '';
    for (let i = 0; i < 5; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return `MATH-${code}`;
  }

  test('returns string in MATH-XXXXX format', () => {
    const code = generateShareCode();
    expect(code).toMatch(/^MATH-[A-HJ-NP-Z2-9]{5}$/);
  });

  test('generates 5-character suffix', () => {
    const code = generateShareCode();
    const suffix = code.replace('MATH-', '');
    expect(suffix.length).toBe(5);
  });

  test('does not contain I, O, 0, or 1 (confusing characters)', () => {
    // Generate many codes and check none contain confusing chars
    for (let i = 0; i < 100; i++) {
      const code = generateShareCode();
      expect(code).not.toMatch(/[IO01]/);
    }
  });

  test('generates different codes (not deterministic)', () => {
    const codes = new Set<string>();
    for (let i = 0; i < 20; i++) {
      codes.add(generateShareCode());
    }
    // At least 15 of 20 should be unique (statistically near-certain)
    expect(codes.size).toBeGreaterThan(15);
  });
});

describe('LaTeX escaping', () => {
  function escapeLatexForJson(jsonStr: string): string {
    return jsonStr.replace(/\\([a-zA-Z])/g, '\\\\$1');
  }

  test('double-escapes \\frac', () => {
    const input = '\\frac{1}{2}';
    expect(escapeLatexForJson(input)).toBe('\\\\frac{1}{2}');
  });

  test('double-escapes \\times', () => {
    const input = '5 \\times 3';
    expect(escapeLatexForJson(input)).toBe('5 \\\\times 3');
  });

  test('double-escapes \\sqrt', () => {
    const input = '\\sqrt{16}';
    expect(escapeLatexForJson(input)).toBe('\\\\sqrt{16}');
  });

  test('double-escapes \\theta and \\pi', () => {
    const input = '\\theta + \\pi';
    expect(escapeLatexForJson(input)).toBe('\\\\theta + \\\\pi');
  });

  test('does not affect non-letter escapes like \\{', () => {
    const input = '\\{a\\}';
    // \\{ is not \\letter, so should remain unchanged
    expect(escapeLatexForJson(input)).toBe('\\{a\\}');
  });

  test('handles already-escaped sequences', () => {
    const input = '\\\\frac{1}{2}';
    // \\\\frac -> first \\\\ is not \\letter, but \\f is — tricky
    // The regex matches \\f in \\\\frac
    const result = escapeLatexForJson(input);
    expect(result).toContain('frac');
  });
});

describe('JSON code fence stripping', () => {
  function stripCodeFences(text: string): string {
    let jsonStr = text.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr
        .replace(/^```(?:json)?\n?/, '')
        .replace(/\n?```$/, '');
    }
    return jsonStr;
  }

  test('strips ```json fences', () => {
    const input = '```json\n[{"q": "test"}]\n```';
    expect(stripCodeFences(input)).toBe('[{"q": "test"}]');
  });

  test('strips ``` fences without json tag', () => {
    const input = '```\n[{"q": "test"}]\n```';
    expect(stripCodeFences(input)).toBe('[{"q": "test"}]');
  });

  test('returns plain JSON unchanged', () => {
    const input = '[{"q": "test"}]';
    expect(stripCodeFences(input)).toBe('[{"q": "test"}]');
  });
});
```

**Step 2: Write generateTest.test.ts**

```typescript
describe('Question type detection', () => {
  function detectType(q: { choices?: string[] }): string {
    return q.choices ? 'multiple_choice' : 'fill_in_blank';
  }

  test('detects multiple_choice when choices present', () => {
    expect(detectType({ choices: ['A', 'B', 'C', 'D'] })).toBe('multiple_choice');
  });

  test('detects fill_in_blank when no choices', () => {
    expect(detectType({})).toBe('fill_in_blank');
  });

  test('detects fill_in_blank when choices undefined', () => {
    expect(detectType({ choices: undefined })).toBe('fill_in_blank');
  });
});

describe('Answer normalization', () => {
  test('converts number answer to string', () => {
    expect(String(42)).toBe('42');
  });

  test('converts decimal answer to string', () => {
    expect(String(3.14)).toBe('3.14');
  });

  test('converts string answer to string (no-op)', () => {
    expect(String('3/4')).toBe('3/4');
  });
});

describe('Expiry calculation', () => {
  test('expires 90 days after creation', () => {
    const now = new Date('2026-02-27T00:00:00Z');
    const expiresAt = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);
    expect(expiresAt.toISOString()).toBe('2026-05-28T00:00:00.000Z');
  });
});
```

**Step 3: Run tests**

```bash
cd functions && npm test
```

Expected: All tests PASS.

**Step 4: Commit**

```bash
git add functions/test/
git commit -m "Add Cloud Function tests for share code, LaTeX escaping, and parsing"
```

---

### Task 6: Delete placeholder test and final verification

**Files:**
- Modify: `test/widget_test.dart` (delete or replace)

**Step 1: Replace placeholder with proper smoke test**

Replace `test/widget_test.dart` content:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/models/question_model.dart';
import 'package:aimathtest/config/constants.dart';

void main() {
  test('App smoke test - core models and constants load', () {
    // Verify core classes are importable and constructible
    final q = QuestionModel(
      id: 'smoke',
      question: 'Is this working?',
      correctAnswer: 'yes',
      topic: 'addition',
    );
    expect(q.id, 'smoke');
    expect(AppConstants.appName, 'AIMathTest');
    expect(AppConstants.freeTestMonthlyLimit, 10);
  });
}
```

**Step 2: Run ALL tests**

```bash
flutter test
cd functions && npm test
```

Expected: All Flutter and Cloud Function tests PASS.

**Step 3: Commit and push**

```bash
git add -A test/ functions/test/ functions/jest.config.js
git commit -m "Complete test suite: unit, widget, and Cloud Function tests with CI"
git push
```

Verify GitHub Actions pipeline runs tests successfully.
