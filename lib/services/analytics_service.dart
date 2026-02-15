import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logSignUp() => _analytics.logSignUp(signUpMethod: 'google');

  Future<void> logLogin() => _analytics.logLogin(loginMethod: 'google');

  Future<void> logProfileCreated(int grade) =>
      _analytics.logEvent(name: 'profile_created', parameters: {'grade': grade});

  Future<void> logOnboardingCompleted(int timeSpent) =>
      _analytics.logEvent(
        name: 'onboarding_completed',
        parameters: {'time_spent': timeSpent},
      );

  Future<void> logTestStarted({
    required List<String> topics,
    required int difficulty,
    required int questionCount,
    required bool timed,
  }) =>
      _analytics.logEvent(
        name: 'test_started',
        parameters: {
          'topics': topics.join(','),
          'difficulty': difficulty,
          'question_count': questionCount,
          'timed': timed,
        },
      );

  Future<void> logTestCompleted({
    required double score,
    required int timeTaken,
    required List<String> topics,
  }) =>
      _analytics.logEvent(
        name: 'test_completed',
        parameters: {
          'score': score,
          'time_taken': timeTaken,
          'topics': topics.join(','),
        },
      );

  Future<void> logTestShared(String testId) =>
      _analytics.logEvent(
        name: 'test_shared',
        parameters: {'test_id': testId},
      );

  Future<void> logTestRetaken(String testId, double previousScore) =>
      _analytics.logEvent(
        name: 'test_retaken',
        parameters: {'test_id': testId, 'previous_score': previousScore},
      );

  Future<void> logProfileSwitched() =>
      _analytics.logEvent(name: 'profile_switched');

  Future<void> logProgressViewed(String profileId) =>
      _analytics.logEvent(
        name: 'progress_viewed',
        parameters: {'profile_id': profileId},
      );
}
