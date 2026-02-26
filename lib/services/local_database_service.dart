import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../models/test_model.dart';
import '../models/attempt_model.dart';
import '../models/feedback_model.dart';
import 'dart:async';

/// In-memory database for local demo mode (no Firebase needed).
class LocalDatabaseService {
  // In-memory storage
  final Map<String, UserModel> _users = {};
  final Map<String, List<ProfileModel>> _profiles = {};
  final Map<String, TestModel> _tests = {};
  final List<AttemptModel> _attempts = [];

  // Stream controllers for reactive updates
  final _profileStreamControllers =
      <String, StreamController<List<ProfileModel>>>{};
  final _attemptStreamControllers =
      <String, StreamController<List<AttemptModel>>>{};

  // ── Users ──

  Future<UserModel?> getUser(String userId) async {
    return _users[userId];
  }

  Future<void> createOrUpdateUser(UserModel user) async {
    _users[user.id] = user;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    final user = _users[userId];
    if (user == null) return;

    _users[userId] = user.copyWith(
      onboardingCompleted: data['onboardingCompleted'] as bool? ??
          user.onboardingCompleted,
      lastActiveProfileId: data['lastActiveProfileId'] as String? ??
          user.lastActiveProfileId,
    );
  }

  // ── Profiles ──

  StreamController<List<ProfileModel>> _getProfileController(String parentId) {
    if (!_profileStreamControllers.containsKey(parentId)) {
      _profileStreamControllers[parentId] =
          StreamController<List<ProfileModel>>.broadcast();
    }
    return _profileStreamControllers[parentId]!;
  }

  void _notifyProfileChange(String parentId) {
    final profiles = _profiles[parentId] ?? [];
    _getProfileController(parentId).add(List.from(profiles));
  }

  Stream<List<ProfileModel>> profilesStream(String parentId) {
    final controller = _getProfileController(parentId);
    // Emit current state immediately
    Future.microtask(() => _notifyProfileChange(parentId));
    return controller.stream;
  }

  Future<ProfileModel> createProfile(ProfileModel profile) async {
    final id = 'profile_${DateTime.now().millisecondsSinceEpoch}';
    final newProfile = ProfileModel(
      id: id,
      parentId: profile.parentId,
      name: profile.name,
      avatar: profile.avatar,
      grade: profile.grade,
      createdAt: profile.createdAt,
      stats: profile.stats,
    );

    _profiles.putIfAbsent(profile.parentId, () => []);
    _profiles[profile.parentId]!.add(newProfile);
    _notifyProfileChange(profile.parentId);
    return newProfile;
  }

  Future<void> updateProfile(ProfileModel profile) async {
    final list = _profiles[profile.parentId];
    if (list == null) return;

    final index = list.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      list[index] = profile;
      _notifyProfileChange(profile.parentId);
    }
  }

  Future<void> deleteProfile(String parentId, String profileId) async {
    _profiles[parentId]?.removeWhere((p) => p.id == profileId);
    _notifyProfileChange(parentId);
  }

  Future<void> updateProfileStats(
    String parentId,
    String profileId,
    ProfileStats stats,
  ) async {
    final list = _profiles[parentId];
    if (list == null) return;

    final index = list.indexWhere((p) => p.id == profileId);
    if (index >= 0) {
      list[index] = list[index].copyWith(stats: stats);
      _notifyProfileChange(parentId);
    }
  }

  // ── Tests ──

  Future<void> saveTest(TestModel test) async {
    _tests[test.id] = test;
  }

  Future<TestModel?> getTest(String testId) async {
    return _tests[testId];
  }

  Future<TestModel?> getTestByShareCode(String shareCode) async {
    return _tests.values
        .where((t) => t.shareCode == shareCode)
        .firstOrNull;
  }

  // ── Attempts ──

  StreamController<List<AttemptModel>> _getAttemptController(String key) {
    if (!_attemptStreamControllers.containsKey(key)) {
      _attemptStreamControllers[key] =
          StreamController<List<AttemptModel>>.broadcast();
    }
    return _attemptStreamControllers[key]!;
  }

  void _notifyAttemptChange(String parentId, String profileId) {
    final key = '${parentId}_$profileId';
    final filtered = _attempts
        .where((a) => a.parentId == parentId && a.profileId == profileId)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    _getAttemptController(key).add(List.from(filtered));
  }

  Future<void> saveAttempt(AttemptModel attempt) async {
    _attempts.add(attempt);
    _notifyAttemptChange(attempt.parentId, attempt.profileId);
  }

  Stream<List<AttemptModel>> attemptsStream(String parentId, String profileId) {
    final key = '${parentId}_$profileId';
    final controller = _getAttemptController(key);
    // Emit current state immediately
    Future.microtask(() => _notifyAttemptChange(parentId, profileId));
    return controller.stream;
  }

  Future<List<AttemptModel>> getRecentAttempts(
    String parentId,
    String profileId, {
    int limit = 20,
  }) async {
    return _attempts
        .where((a) => a.parentId == parentId && a.profileId == profileId)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt))
      ..take(limit).toList();
  }

  Future<List<AttemptModel>> getAttemptsForTest(
    String testId,
    String profileId,
  ) async {
    return _attempts
        .where((a) => a.testId == testId && a.profileId == profileId)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  Future<int> getTodayAttemptCount(String parentId, String profileId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _attempts
        .where((a) =>
            a.parentId == parentId &&
            a.profileId == profileId &&
            a.completedAt.isAfter(startOfDay))
        .length;
  }

  Future<void> saveFeedback(FeedbackModel feedback) async {
    // No-op in local mode
  }

  void dispose() {
    for (final c in _profileStreamControllers.values) {
      c.close();
    }
    for (final c in _attemptStreamControllers.values) {
      c.close();
    }
  }
}
