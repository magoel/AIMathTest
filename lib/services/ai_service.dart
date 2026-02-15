import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/question_model.dart';
import '../models/test_model.dart';
import '../models/attempt_model.dart';
import '../config/constants.dart';

class AIService {
  final _uuid = const Uuid();

  /// Generate a test locally with grade-appropriate math problems.
  /// When Firebase Cloud Functions are deployed, this can call Gemini API instead.
  Future<TestModel> generateTest({
    required String parentId,
    required String profileId,
    required String profileName,
    required int grade,
    required List<String> topics,
    required int difficulty,
    required int questionCount,
    required bool timed,
    List<AttemptModel>? recentAttempts,
  }) async {
    // Small delay to simulate generation
    await Future.delayed(const Duration(milliseconds: 300));

    return _generateLocally(
      parentId: parentId,
      profileId: profileId,
      profileName: profileName,
      grade: grade,
      topics: topics,
      difficulty: difficulty,
      questionCount: questionCount,
      timed: timed,
    );
  }

  TestModel _generateLocally({
    required String parentId,
    required String profileId,
    required String profileName,
    required int grade,
    required List<String> topics,
    required int difficulty,
    required int questionCount,
    required bool timed,
  }) {
    final random = Random();
    final testId = _uuid.v4();
    final shareCode = _generateShareCode();
    final questions = <QuestionModel>[];

    for (int i = 0; i < questionCount; i++) {
      final topic = topics[i % topics.length];
      final q = _generateQuestion(topic, difficulty, grade, random);
      questions.add(QuestionModel(
        id: _uuid.v4(),
        question: q['question']!,
        correctAnswer: q['answer']!,
        topic: topic,
      ));
    }

    return TestModel(
      id: testId,
      shareCode: shareCode,
      createdBy: TestCreatedBy(
        parentId: parentId,
        profileId: profileId,
        profileName: profileName,
      ),
      config: TestConfig(
        topics: topics,
        difficulty: difficulty,
        questionCount: questionCount,
        timed: timed,
        timeLimitSeconds: timed ? questionCount * 60 : null,
      ),
      questions: questions,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(
        const Duration(days: AppConstants.testExpiryDays),
      ),
    );
  }

  Map<String, String> _generateQuestion(
    String topic,
    int difficulty,
    int grade,
    Random random,
  ) {
    final maxNum = (difficulty * 5) + (grade * 3) + 5;

    switch (topic) {
      case 'addition':
        final a = random.nextInt(maxNum) + 1;
        final b = random.nextInt(maxNum) + 1;
        return {'question': '$a + $b = ?', 'answer': '${a + b}'};
      case 'subtraction':
        final b = random.nextInt(maxNum) + 1;
        final a = b + random.nextInt(maxNum) + 1;
        return {'question': '$a - $b = ?', 'answer': '${a - b}'};
      case 'multiplication':
        final a = random.nextInt((maxNum ~/ 2).clamp(2, 20)) + 1;
        final b = random.nextInt((maxNum ~/ 2).clamp(2, 15)) + 1;
        return {'question': '$a × $b = ?', 'answer': '${a * b}'};
      case 'division':
        final b = random.nextInt((maxNum ~/ 3).clamp(2, 12)) + 2;
        final answer = random.nextInt((maxNum ~/ 2).clamp(2, 15)) + 1;
        final a = b * answer;
        return {'question': '$a ÷ $b = ?', 'answer': '$answer'};
      case 'fractions':
        final denom = [2, 3, 4, 5, 6, 8, 10][random.nextInt(7)];
        final num1 = random.nextInt(denom) + 1;
        final num2 = random.nextInt(denom) + 1;
        final sum = num1 + num2;
        if (sum % denom == 0) {
          return {
            'question': '$num1/$denom + $num2/$denom = ?',
            'answer': '${sum ~/ denom}',
          };
        }
        return {
          'question': '$num1/$denom + $num2/$denom = ?',
          'answer': '$sum/$denom',
        };
      case 'decimals':
        final a = (random.nextInt(maxNum * 10) + 1) / 10.0;
        final b = (random.nextInt(maxNum * 10) + 1) / 10.0;
        final sum = ((a + b) * 10).round() / 10.0;
        return {'question': '$a + $b = ?', 'answer': '$sum'};
      case 'percentages':
        final percent = [10, 20, 25, 50, 75][random.nextInt(5)];
        final number = (random.nextInt(20) + 1) * 4;
        final answer = (percent * number) ~/ 100;
        return {'question': '$percent% of $number = ?', 'answer': '$answer'};
      case 'algebra':
        final x = random.nextInt(maxNum ~/ 2) + 1;
        final b = random.nextInt(maxNum) + 1;
        final result = x + b;
        return {'question': 'x + $b = $result, x = ?', 'answer': '$x'};
      case 'geometry':
        final side = random.nextInt(maxNum ~/ 2) + 1;
        return {
          'question': 'Perimeter of a square with side $side = ?',
          'answer': '${side * 4}',
        };
      case 'word_problems':
        final a = random.nextInt(maxNum) + 1;
        final b = random.nextInt(maxNum) + 1;
        return {
          'question': 'Sam has $a apples and gets $b more. How many total?',
          'answer': '${a + b}',
        };
      default:
        final a = random.nextInt(maxNum) + 1;
        final b = random.nextInt(maxNum) + 1;
        return {'question': '$a + $b = ?', 'answer': '${a + b}'};
    }
  }

  String _generateShareCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final code =
        List.generate(5, (_) => chars[random.nextInt(chars.length)]).join();
    return 'MATH-$code';
  }
}
