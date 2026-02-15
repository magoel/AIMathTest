import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_model.dart';

class TestConfig {
  final List<String> topics;
  final int difficulty;
  final int questionCount;
  final bool timed;
  final int? timeLimitSeconds;

  const TestConfig({
    required this.topics,
    required this.difficulty,
    required this.questionCount,
    this.timed = false,
    this.timeLimitSeconds,
  });

  factory TestConfig.fromMap(Map<String, dynamic> data) {
    return TestConfig(
      topics: List<String>.from(data['topics'] ?? []),
      difficulty: data['difficulty'] ?? 5,
      questionCount: data['questionCount'] ?? 10,
      timed: data['timed'] ?? false,
      timeLimitSeconds: data['timeLimitSeconds'],
    );
  }

  Map<String, dynamic> toMap() => {
    'topics': topics,
    'difficulty': difficulty,
    'questionCount': questionCount,
    'timed': timed,
    'timeLimitSeconds': timeLimitSeconds,
  };
}

class TestCreatedBy {
  final String parentId;
  final String profileId;
  final String profileName;

  const TestCreatedBy({
    required this.parentId,
    required this.profileId,
    required this.profileName,
  });

  factory TestCreatedBy.fromMap(Map<String, dynamic> data) {
    return TestCreatedBy(
      parentId: data['parentId'] ?? '',
      profileId: data['profileId'] ?? '',
      profileName: data['profileName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'parentId': parentId,
    'profileId': profileId,
    'profileName': profileName,
  };
}

class TestModel {
  final String id;
  final String shareCode;
  final TestCreatedBy createdBy;
  final TestConfig config;
  final List<QuestionModel> questions;
  final DateTime createdAt;
  final DateTime expiresAt;

  const TestModel({
    required this.id,
    required this.shareCode,
    required this.createdBy,
    required this.config,
    required this.questions,
    required this.createdAt,
    required this.expiresAt,
  });

  factory TestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestModel(
      id: doc.id,
      shareCode: data['shareCode'] ?? '',
      createdBy: TestCreatedBy.fromMap(data['createdBy'] ?? {}),
      config: TestConfig.fromMap(data['config'] ?? {}),
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromMap(q as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 90)),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'shareCode': shareCode,
    'createdBy': createdBy.toMap(),
    'config': config.toMap(),
    'questions': questions.map((q) => q.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
  };
}
