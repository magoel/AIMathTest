# Design: Comprehensive Test Suite with CI Integration

> Date: 2026-02-27
> Status: Approved

## Goal

Add unit, provider, widget, and Cloud Function tests to the AIMathTest project. Integrate into GitHub Actions so tests gate deployment.

## Test Structure

```
test/
├── unit/
│   ├── models/
│   │   ├── question_model_test.dart
│   │   ├── test_model_test.dart
│   │   └── attempt_model_test.dart
│   ├── config/
│   │   ├── board_curriculum_test.dart
│   │   └── constants_test.dart
│   └── helpers/
│       └── friendly_error_test.dart
├── providers/
│   ├── subscription_provider_test.dart
│   └── test_provider_test.dart
├── widgets/
│   ├── math_text_test.dart
│   ├── score_display_test.dart
│   └── subscription_card_test.dart
└── screens/
    └── test_taking_screen_test.dart

functions/test/
├── generateTest.test.ts
└── helpers.test.ts
```

## Layer 1: Unit Tests (Pure Dart)

| File | Tests | Key Cases |
|------|-------|-----------|
| question_model_test.dart | isMultipleChoice, fromMap/toMap | MCQ vs fill-in-blank, null choices |
| test_model_test.dart | Serialization round-trip | Defaults, share code, expiry |
| attempt_model_test.dart | Score/percentage, isRetake | Zero, perfect, retake flag |
| board_curriculum_test.dart | getAvailableTopics | Grade windowing, K-2 cumulative, min 4 topics, all 3 boards |
| constants_test.dart | scoreMessage, scoreEmoji, adminEmails | Score thresholds, admin email set |
| friendly_error_test.dart | _friendlyError mapping | All 6 patterns + fallback |

## Layer 2: Provider Tests

| File | Tests | Key Cases |
|------|-------|-----------|
| subscription_provider_test.dart | isPremiumProvider admin bypass | Admin → true, non-admin free → false, non-admin premium → true |
| test_provider_test.dart | monthGenerationCountProvider | Returns 0 unauthenticated, autoDispose |

## Layer 3: Widget Tests

| File | Tests | Key Cases |
|------|-------|-----------|
| math_text_test.dart | MathText renders LaTeX/plain | Plain, $\frac{1}{2}$, mixed, cleanLatex edge cases |
| score_display_test.dart | Score display | 0%, 50%, 100% |
| subscription_card_test.dart | Free vs premium card | "generations remaining" vs "Premium Plan" |

## Layer 4: Cloud Function Tests (Jest)

| File | Tests | Key Cases |
|------|-------|-----------|
| generateTest.test.ts | JSON parsing, LaTeX escaping | Double-escape \frac/\times, malformed JSON, share code format |
| helpers.test.ts | generateShareCode, timestamps | Code format (5 chars), expiry calculation |

## CI Integration

Add to `.github/workflows/deploy.yml` before build/deploy:

```yaml
- name: Run Flutter tests
  run: flutter test

- name: Run Cloud Function tests
  run: cd functions && npm test
```

Tests gate deployment — failure stops the pipeline.

## Dependencies to Add

Flutter (pubspec.yaml devDependencies):
- mockito: ^5.4.4
- build_runner: ^2.4.8

Cloud Functions (functions/package.json devDependencies):
- jest: ^29.7.0
- ts-jest: ^29.1.1
- @types/jest: ^29.5.11
