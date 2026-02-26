import 'package:cloud_functions/cloud_functions.dart';
import '../models/question_model.dart';
import '../models/test_model.dart';
import '../models/attempt_model.dart';
import '../config/app_config.dart';
import '../config/constants.dart';

class AIService {
  /// Generate a test via Cloud Function (Gemini Flash).
  /// Throws on failure — no local fallback.
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
    if (!AppConfig.useFirebase) {
      throw Exception('Test generation requires an internet connection.');
    }

    final callable = FirebaseFunctions.instance.httpsCallable(
      'generateTest',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
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
}
