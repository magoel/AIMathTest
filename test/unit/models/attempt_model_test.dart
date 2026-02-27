import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/models/attempt_model.dart';

void main() {
  group('AnswerModel', () {
    group('fromMap', () {
      test('parses a complete map correctly', () {
        final map = {
          'questionId': 'q1',
          'userAnswer': '42',
          'isCorrect': true,
        };

        final answer = AnswerModel.fromMap(map);

        expect(answer.questionId, equals('q1'));
        expect(answer.userAnswer, equals('42'));
        expect(answer.isCorrect, isTrue);
      });

      test('defaults missing questionId to empty string', () {
        final answer = AnswerModel.fromMap(<String, dynamic>{
          'userAnswer': '7',
          'isCorrect': true,
        });
        expect(answer.questionId, equals(''));
      });

      test('defaults missing userAnswer to empty string', () {
        final answer = AnswerModel.fromMap(<String, dynamic>{
          'questionId': 'q2',
          'isCorrect': false,
        });
        expect(answer.userAnswer, equals(''));
      });

      test('defaults missing isCorrect to false', () {
        final answer = AnswerModel.fromMap(<String, dynamic>{
          'questionId': 'q3',
          'userAnswer': '5',
        });
        expect(answer.isCorrect, isFalse);
      });

      test('handles completely empty map with all defaults', () {
        final answer = AnswerModel.fromMap(<String, dynamic>{});

        expect(answer.questionId, equals(''));
        expect(answer.userAnswer, equals(''));
        expect(answer.isCorrect, isFalse);
      });
    });

    group('toMap round-trip', () {
      test('round-trips a correct answer', () {
        const original = AnswerModel(
          questionId: 'q10',
          userAnswer: '\\frac{5}{6}',
          isCorrect: true,
        );

        final map = original.toMap();
        final restored = AnswerModel.fromMap(map);

        expect(restored.questionId, equals(original.questionId));
        expect(restored.userAnswer, equals(original.userAnswer));
        expect(restored.isCorrect, equals(original.isCorrect));
      });

      test('round-trips an incorrect answer', () {
        const original = AnswerModel(
          questionId: 'q11',
          userAnswer: '99',
          isCorrect: false,
        );

        final map = original.toMap();
        final restored = AnswerModel.fromMap(map);

        expect(restored.questionId, equals(original.questionId));
        expect(restored.userAnswer, equals(original.userAnswer));
        expect(restored.isCorrect, equals(original.isCorrect));
      });

      test('toMap produces expected keys and values', () {
        const answer = AnswerModel(
          questionId: 'q5',
          userAnswer: '12',
          isCorrect: true,
        );

        final map = answer.toMap();

        expect(map, equals({
          'questionId': 'q5',
          'userAnswer': '12',
          'isCorrect': true,
        }));
      });
    });
  });

  group('AttemptModel', () {
    final testDate = DateTime(2026, 2, 15, 10, 30);

    AttemptModel createAttempt({
      bool isRetake = false,
      String? previousAttemptId,
    }) {
      return AttemptModel(
        id: 'attempt1',
        testId: 'test1',
        parentId: 'parent1',
        profileId: 'profile1',
        answers: const [
          AnswerModel(questionId: 'q1', userAnswer: '4', isCorrect: true),
          AnswerModel(questionId: 'q2', userAnswer: '7', isCorrect: false),
          AnswerModel(questionId: 'q3', userAnswer: '9', isCorrect: true),
        ],
        score: 2,
        totalQuestions: 3,
        percentage: 66.67,
        timeTaken: 120,
        shuffleOrder: [2, 0, 1],
        isRetake: isRetake,
        previousAttemptId: previousAttemptId,
        completedAt: testDate,
      );
    }

    group('constructor defaults', () {
      test('stores score and percentage correctly', () {
        final attempt = createAttempt();

        expect(attempt.score, equals(2));
        expect(attempt.totalQuestions, equals(3));
        expect(attempt.percentage, equals(66.67));
      });

      test('isRetake defaults to false', () {
        final attempt = createAttempt();

        expect(attempt.isRetake, isFalse);
        expect(attempt.previousAttemptId, isNull);
      });

      test('retake has isRetake true and previousAttemptId set', () {
        final attempt = createAttempt(
          isRetake: true,
          previousAttemptId: 'attempt0',
        );

        expect(attempt.isRetake, isTrue);
        expect(attempt.previousAttemptId, equals('attempt0'));
      });

      test('testTopics and testShareCode default to null', () {
        final attempt = createAttempt();

        expect(attempt.testTopics, isNull);
        expect(attempt.testShareCode, isNull);
      });
    });

    group('toFirestore', () {
      test('produces correct map for a first attempt', () {
        final attempt = createAttempt();
        final map = attempt.toFirestore();

        expect(map['testId'], equals('test1'));
        expect(map['parentId'], equals('parent1'));
        expect(map['profileId'], equals('profile1'));
        expect(map['score'], equals(2));
        expect(map['totalQuestions'], equals(3));
        expect(map['percentage'], equals(66.67));
        expect(map['timeTaken'], equals(120));
        expect(map['shuffleOrder'], equals([2, 0, 1]));
        expect(map['isRetake'], isFalse);
        expect(map['previousAttemptId'], isNull);
        expect(map['completedAt'], isA<Timestamp>());
      });

      test('serializes answers list correctly', () {
        final attempt = createAttempt();
        final map = attempt.toFirestore();
        final answers = map['answers'] as List;

        expect(answers.length, equals(3));
        expect(answers[0], equals({
          'questionId': 'q1',
          'userAnswer': '4',
          'isCorrect': true,
        }));
        expect(answers[1]['isCorrect'], isFalse);
      });

      test('includes retake fields when isRetake is true', () {
        final attempt = createAttempt(
          isRetake: true,
          previousAttemptId: 'attempt0',
        );
        final map = attempt.toFirestore();

        expect(map['isRetake'], isTrue);
        expect(map['previousAttemptId'], equals('attempt0'));
      });

      test('completedAt is serialized as Firestore Timestamp', () {
        final attempt = createAttempt();
        final map = attempt.toFirestore();
        final timestamp = map['completedAt'] as Timestamp;

        expect(timestamp.toDate(), equals(testDate));
      });

      test('does not include id in toFirestore output', () {
        final attempt = createAttempt();
        final map = attempt.toFirestore();

        expect(map.containsKey('id'), isFalse);
      });
    });
  });
}
