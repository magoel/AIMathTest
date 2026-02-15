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

  /// Call the generateTest Cloud Function (which calls Gemini 1.5 Flash).
  Future<TestModel> _generateViaCloudFunction({
    required String parentId,
    required String profileId,
    required String profileName,
    required int grade,
    required List<String> topics,
    required int difficulty,
    required int questionCount,
    required bool timed,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('generateTest');
    final result = await callable.call({
      'profileId': profileId,
      'grade': grade,
      'topics': topics,
      'difficulty': difficulty,
      'questionCount': questionCount,
      'timed': timed,
    });

    final data = result.data as Map<String, dynamic>;
    final questions = (data['questions'] as List<dynamic>)
        .map((q) => QuestionModel.fromMap(q as Map<String, dynamic>))
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
