import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/question_model.dart';
import '../models/test_model.dart';
import '../models/attempt_model.dart';
import '../config/app_config.dart';
import '../config/constants.dart';

class AIService {
  final _uuid = const Uuid();

  /// Generate a test via Cloud Function (Gemini Flash) with local fallback.
  Future<TestModel> generateTest({
    required String parentId,
    required String profileId,
    required String profileName,
    required int grade,
    String board = 'cbse',
    required List<String> topics,
    required int difficulty,
    required int questionCount,
    required bool timed,
    List<AttemptModel>? recentAttempts,
  }) async {
    // Try Cloud Function (Gemini) when Firebase is enabled
    if (AppConfig.useFirebase) {
      try {
        return await _generateViaCloudFunction(
          parentId: parentId,
          profileId: profileId,
          profileName: profileName,
          grade: grade,
          board: board,
          topics: topics,
          difficulty: difficulty,
          questionCount: questionCount,
          timed: timed,
        );
      } catch (e) {
        debugPrint('Cloud Function failed, falling back to local: $e');
      }
    }

    // Fallback: generate locally
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

  /// Call the generateTest Cloud Function (which calls Gemini 2.0 Flash).
  Future<TestModel> _generateViaCloudFunction({
    required String parentId,
    required String profileId,
    required String profileName,
    required int grade,
    required String board,
    required List<String> topics,
    required int difficulty,
    required int questionCount,
    required bool timed,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('generateTest');
    final result = await callable.call({
      'profileId': profileId,
      'grade': grade,
      'board': board,
      'topics': topics,
      'difficulty': difficulty,
      'questionCount': questionCount,
      'timed': timed,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final questions = (data['questions'] as List<dynamic>)
        .map((q) => QuestionModel.fromMap(Map<String, dynamic>.from(q as Map)))
        .toList();

    final testId = data['testId'] as String;
    final shareCode = data['shareCode'] as String;

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

  /// Local fallback test generation (no API needed).
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
    String topic, int difficulty, int grade, Random random,
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
          return {'question': '$num1/$denom + $num2/$denom = ?', 'answer': '${sum ~/ denom}'};
        }
        return {'question': '$num1/$denom + $num2/$denom = ?', 'answer': '$sum/$denom'};
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
        return {'question': 'Perimeter of a square with side $side = ?', 'answer': '${side * 4}'};
      case 'word_problems':
        final a = random.nextInt(maxNum) + 1;
        final b = random.nextInt(maxNum) + 1;
        return {'question': 'Sam has $a apples and gets $b more. How many total?', 'answer': '${a + b}'};
      case 'measurement':
        final cm = (random.nextInt(maxNum) + 1) * 10;
        final m = cm ~/ 100;
        final rem = cm % 100;
        return {'question': 'Convert $cm cm to meters = ?', 'answer': '$m.${rem.toString().padLeft(2, '0')}'};
      case 'data_handling':
        final values = List.generate(5, (_) => random.nextInt(maxNum) + 1);
        final sum = values.reduce((a, b) => a + b);
        final mean = sum ~/ values.length;
        return {'question': 'Mean of ${values.join(", ")} = ?', 'answer': '$mean'};
      case 'ratio_proportion':
        final a = random.nextInt(10) + 2;
        final b = random.nextInt(10) + 2;
        final multiplier = random.nextInt(5) + 2;
        final bigA = a * multiplier;
        return {'question': 'If $a:$b = $bigA:x, then x = ?', 'answer': '${b * multiplier}'};
      case 'probability':
        final total = [6, 8, 10, 12][random.nextInt(4)];
        final favorable = random.nextInt(total - 1) + 1;
        return {'question': 'A bag has $total balls, $favorable are red. Probability of picking red = ?', 'answer': '$favorable/$total'};
      case 'trigonometry':
        final angles = [30, 45, 60];
        final angle = angles[random.nextInt(3)];
        final sinValues = {30: '1/2', 45: '1/√2', 60: '√3/2'};
        return {'question': 'sin($angle°) = ?', 'answer': sinValues[angle]!};
      case 'number_systems':
        final a = random.nextInt(20) + 2;
        final sqr = a * a;
        return {'question': '√$sqr = ?', 'answer': '$a'};
      case 'calculus':
        final coeff = random.nextInt(8) + 2;
        final power = random.nextInt(4) + 2;
        final newCoeff = coeff * power;
        final newPower = power - 1;
        return {'question': 'd/dx($coeff x^$power) = ?', 'answer': '${newCoeff}x^$newPower'};
      default:
        final a = random.nextInt(maxNum) + 1;
        final b = random.nextInt(maxNum) + 1;
        return {'question': '$a + $b = ?', 'answer': '${a + b}'};
    }
  }

  String _generateShareCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final code = List.generate(5, (_) => chars[random.nextInt(chars.length)]).join();
    return 'MATH-$code';
  }
}
