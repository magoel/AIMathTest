class AppConstants {
  static const String appName = 'AIMathTest';
  static const String tagline = 'AI-powered math practice for kids K-12';

  static const List<String> avatars = [
    '🦊', '🐼', '🦁', '🐸', '🦄', '🐶', '🐱', '🐰',
    '🐯', '🐮', '🐷', '🐵', '🦉', '🐧', '🦋', '🐢',
  ];

  static const List<String> gradeLabels = [
    'Kindergarten', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4',
    'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9',
    'Grade 10', 'Grade 11', 'Grade 12',
  ];

  static const Map<String, TopicInfo> topics = {
    'addition': TopicInfo('Addition', '➕'),
    'subtraction': TopicInfo('Subtraction', '➖'),
    'multiplication': TopicInfo('Multiplication', '✖️'),
    'division': TopicInfo('Division', '➗'),
    'fractions': TopicInfo('Fractions', '½'),
    'decimals': TopicInfo('Decimals', '.5'),
    'percentages': TopicInfo('Percentages', '%'),
    'geometry': TopicInfo('Geometry', '📐'),
    'algebra': TopicInfo('Algebra', 'x'),
    'word_problems': TopicInfo('Word Problems', '📝'),
  };

  static const List<int> questionCounts = [5, 10, 15, 20];

  static String scoreMessage(double percentage) {
    if (percentage >= 100) return 'Perfect Score!';
    if (percentage >= 80) return 'Great Job!';
    if (percentage >= 60) return 'Good Effort!';
    return 'Keep Practicing!';
  }

  static String scoreEmoji(double percentage) {
    if (percentage >= 100) return '🌟';
    if (percentage >= 80) return '🎉';
    if (percentage >= 60) return '👍';
    return '💪';
  }

  static const int testExpiryDays = 90;
  static const int maxRecentTests = 5;
  static const int recentAttemptsForAI = 20;

  // Subscription
  static const int freeTestDailyLimit = 5;
  static const String monthlyProductId = 'premium_monthly';
  static const String annualProductId = 'premium_annual';
  static const Set<String> subscriptionProductIds = {
    monthlyProductId,
    annualProductId,
  };
}

class TopicInfo {
  final String label;
  final String icon;
  const TopicInfo(this.label, this.icon);
}
