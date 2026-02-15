import 'package:cloud_firestore/cloud_firestore.dart';

class AnswerModel {
  final String questionId;
  final String userAnswer;
  final bool isCorrect;

  const AnswerModel({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
  });

  factory AnswerModel.fromMap(Map<String, dynamic> data) {
    return AnswerModel(
      questionId: data['questionId'] ?? '',
      userAnswer: data['userAnswer'] ?? '',
      isCorrect: data['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'questionId': questionId,
    'userAnswer': userAnswer,
    'isCorrect': isCorrect,
  };
}

class AttemptModel {
  final String id;
  final String testId;
  final String parentId;
  final String profileId;
  final List<AnswerModel> answers;
  final int score;
  final int totalQuestions;
  final double percentage;
  final int timeTaken;
  final List<int> shuffleOrder;
  final bool isRetake;
  final String? previousAttemptId;
  final DateTime completedAt;

  // Joined data (not stored in Firestore)
  final List<String>? testTopics;
  final String? testShareCode;

  const AttemptModel({
    required this.id,
    required this.testId,
    required this.parentId,
    required this.profileId,
    required this.answers,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.timeTaken,
    required this.shuffleOrder,
    this.isRetake = false,
    this.previousAttemptId,
    required this.completedAt,
    this.testTopics,
    this.testShareCode,
  });

  factory AttemptModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttemptModel(
      id: doc.id,
      testId: data['testId'] ?? '',
      parentId: data['parentId'] ?? '',
      profileId: data['profileId'] ?? '',
      answers: (data['answers'] as List<dynamic>? ?? [])
          .map((a) => AnswerModel.fromMap(a as Map<String, dynamic>))
          .toList(),
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      percentage: (data['percentage'] ?? 0).toDouble(),
      timeTaken: data['timeTaken'] ?? 0,
      shuffleOrder: List<int>.from(data['shuffleOrder'] ?? []),
      isRetake: data['isRetake'] ?? false,
      previousAttemptId: data['previousAttemptId'],
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      testTopics: data['testTopics'] != null
          ? List<String>.from(data['testTopics'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'testId': testId,
    'parentId': parentId,
    'profileId': profileId,
    'answers': answers.map((a) => a.toMap()).toList(),
    'score': score,
    'totalQuestions': totalQuestions,
    'percentage': percentage,
    'timeTaken': timeTaken,
    'shuffleOrder': shuffleOrder,
    'isRetake': isRetake,
    'previousAttemptId': previousAttemptId,
    'completedAt': Timestamp.fromDate(completedAt),
    'testTopics': testTopics,
  };
}
