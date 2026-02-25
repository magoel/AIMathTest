import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/board_curriculum.dart';

class ProfileStats {
  final int totalTests;
  final double averageScore;
  final int currentStreak;
  final DateTime? lastTestAt;

  const ProfileStats({
    this.totalTests = 0,
    this.averageScore = 0,
    this.currentStreak = 0,
    this.lastTestAt,
  });

  factory ProfileStats.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ProfileStats();
    return ProfileStats(
      totalTests: data['totalTests'] ?? 0,
      averageScore: (data['averageScore'] ?? 0).toDouble(),
      currentStreak: data['currentStreak'] ?? 0,
      lastTestAt: (data['lastTestAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'totalTests': totalTests,
    'averageScore': averageScore,
    'currentStreak': currentStreak,
    'lastTestAt': lastTestAt != null ? Timestamp.fromDate(lastTestAt!) : null,
  };
}

class ProfileModel {
  final String id;
  final String parentId;
  final String name;
  final String avatar;
  final int grade; // 0 = K, 1-12
  final String board; // 'cbse', 'ib', 'cambridge'
  final DateTime createdAt;
  final ProfileStats stats;

  const ProfileModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.avatar,
    required this.grade,
    this.board = 'cbse',
    required this.createdAt,
    this.stats = const ProfileStats(),
  });

  String get gradeLabel => grade == 0 ? 'K' : 'Gr.$grade';

  Board get boardEnum => Board.values.firstWhere(
    (b) => b.name == board,
    orElse: () => Board.cbse,
  );

  String get boardLabel => boardEnum.label;

  factory ProfileModel.fromFirestore(DocumentSnapshot doc, String parentId) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileModel(
      id: doc.id,
      parentId: parentId,
      name: data['name'] ?? '',
      avatar: data['avatar'] ?? '🦊',
      grade: data['grade'] ?? 0,
      board: data['board'] ?? 'cbse',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stats: ProfileStats.fromMap(data['stats']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'avatar': avatar,
    'grade': grade,
    'board': board,
    'createdAt': Timestamp.fromDate(createdAt),
    'stats': stats.toMap(),
  };

  ProfileModel copyWith({
    String? name,
    String? avatar,
    int? grade,
    String? board,
    ProfileStats? stats,
  }) {
    return ProfileModel(
      id: id,
      parentId: parentId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      grade: grade ?? this.grade,
      board: board ?? this.board,
      createdAt: createdAt,
      stats: stats ?? this.stats,
    );
  }
}
