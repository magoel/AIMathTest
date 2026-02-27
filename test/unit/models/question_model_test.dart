import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/models/question_model.dart';

void main() {
  group('QuestionModel', () {
    group('isMultipleChoice getter', () {
      test('returns true when type is multiple_choice and choices is not null',
          () {
        const question = QuestionModel(
          id: 'q1',
          type: 'multiple_choice',
          question: 'What is 2+2?',
          correctAnswer: '4',
          topic: 'addition',
          choices: ['2', '3', '4', '5'],
        );
        expect(question.isMultipleChoice, isTrue);
      });

      test('returns false when type is fill_in_blank', () {
        const question = QuestionModel(
          id: 'q2',
          question: 'What is 3+3?',
          correctAnswer: '6',
          topic: 'addition',
        );
        expect(question.isMultipleChoice, isFalse);
      });

      test('returns false when type is multiple_choice but choices is null',
          () {
        const question = QuestionModel(
          id: 'q3',
          type: 'multiple_choice',
          question: 'What is 5+5?',
          correctAnswer: '10',
          topic: 'addition',
          choices: null,
        );
        expect(question.isMultipleChoice, isFalse);
      });
    });

    group('default type', () {
      test('defaults to fill_in_blank when type is not specified', () {
        const question = QuestionModel(
          id: 'q1',
          question: 'What is 1+1?',
          correctAnswer: '2',
          topic: 'addition',
        );
        expect(question.type, equals('fill_in_blank'));
      });
    });

    group('fromMap', () {
      test('parses complete MCQ data correctly', () {
        final map = {
          'id': 'q1',
          'type': 'multiple_choice',
          'question': 'What is 7 \\times 8?',
          'correctAnswer': '56',
          'topic': 'multiplication',
          'choices': ['48', '54', '56', '63'],
        };

        final question = QuestionModel.fromMap(map);

        expect(question.id, equals('q1'));
        expect(question.type, equals('multiple_choice'));
        expect(question.question, equals('What is 7 \\times 8?'));
        expect(question.correctAnswer, equals('56'));
        expect(question.topic, equals('multiplication'));
        expect(question.choices, equals(['48', '54', '56', '63']));
        expect(question.isMultipleChoice, isTrue);
      });

      test('handles missing fields with defaults', () {
        final question = QuestionModel.fromMap(<String, dynamic>{});

        expect(question.id, equals(''));
        expect(question.type, equals('fill_in_blank'));
        expect(question.question, equals(''));
        expect(question.correctAnswer, equals(''));
        expect(question.topic, equals(''));
        expect(question.choices, isNull);
        expect(question.isMultipleChoice, isFalse);
      });

      test('handles null choices', () {
        final map = {
          'id': 'q2',
          'type': 'fill_in_blank',
          'question': 'What is 10 / 2?',
          'correctAnswer': '5',
          'topic': 'division',
          'choices': null,
        };

        final question = QuestionModel.fromMap(map);
        expect(question.choices, isNull);
        expect(question.isMultipleChoice, isFalse);
      });

      test('parses partial data with some fields missing', () {
        final map = <String, dynamic>{
          'id': 'q5',
          'question': 'Solve x + 3 = 7',
        };

        final question = QuestionModel.fromMap(map);
        expect(question.id, equals('q5'));
        expect(question.type, equals('fill_in_blank'));
        expect(question.question, equals('Solve x + 3 = 7'));
        expect(question.correctAnswer, equals(''));
        expect(question.topic, equals(''));
        expect(question.choices, isNull);
      });
    });

    group('toMap round-trip', () {
      test('round-trips a fill_in_blank question correctly', () {
        const original = QuestionModel(
          id: 'q10',
          type: 'fill_in_blank',
          question: 'What is \\frac{1}{2} + \\frac{1}{3}?',
          correctAnswer: '\\frac{5}{6}',
          topic: 'fractions',
        );

        final map = original.toMap();
        final restored = QuestionModel.fromMap(map);

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.question, equals(original.question));
        expect(restored.correctAnswer, equals(original.correctAnswer));
        expect(restored.topic, equals(original.topic));
        expect(restored.choices, isNull);
        expect(restored.isMultipleChoice, equals(original.isMultipleChoice));
      });

      test('round-trips an MCQ question correctly', () {
        const original = QuestionModel(
          id: 'q11',
          type: 'multiple_choice',
          question: 'What is 9 \\times 9?',
          correctAnswer: '81',
          topic: 'multiplication',
          choices: ['72', '79', '81', '90'],
        );

        final map = original.toMap();
        final restored = QuestionModel.fromMap(map);

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.question, equals(original.question));
        expect(restored.correctAnswer, equals(original.correctAnswer));
        expect(restored.topic, equals(original.topic));
        expect(restored.choices, equals(original.choices));
        expect(restored.isMultipleChoice, equals(original.isMultipleChoice));
      });

      test('toMap omits choices key when choices is null', () {
        const question = QuestionModel(
          id: 'q12',
          question: 'What is 4+4?',
          correctAnswer: '8',
          topic: 'addition',
        );

        final map = question.toMap();
        expect(map.containsKey('choices'), isFalse);
      });

      test('toMap includes choices key when choices is provided', () {
        const question = QuestionModel(
          id: 'q13',
          type: 'multiple_choice',
          question: 'What is 4+4?',
          correctAnswer: '8',
          topic: 'addition',
          choices: ['6', '7', '8', '9'],
        );

        final map = question.toMap();
        expect(map.containsKey('choices'), isTrue);
        expect(map['choices'], equals(['6', '7', '8', '9']));
      });
    });
  });
}
