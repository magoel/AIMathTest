import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../models/test_model.dart';
import '../models/attempt_model.dart';
import '../services/database_service.dart';
import '../services/local_database_service.dart';
import 'auth_provider.dart';

// Firebase Firestore service
final firebaseDatabaseServiceProvider =
    Provider<DatabaseService>((ref) => DatabaseService());

// Local in-memory service
final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  final service = LocalDatabaseService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Convenience getter — screens use this regardless of mode
final databaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  if (AppConfig.useFirebase) {
    // We need a wrapper — see below
    return ref.read(firebaseDatabaseWrapperProvider);
  }
  return ref.read(localDatabaseServiceProvider);
});

// Wraps Firebase DatabaseService in the LocalDatabaseService interface
// so screens can use one type everywhere.
final firebaseDatabaseWrapperProvider = Provider<LocalDatabaseService>((ref) {
  // For Firebase mode, use FirebaseDatabaseWrapper that delegates to Firestore
  return FirebaseDatabaseWrapper(ref.read(firebaseDatabaseServiceProvider));
});

final userProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  if (AppConfig.useFirebase) {
    final db = ref.read(firebaseDatabaseServiceProvider);
    var userModel = await db.getUser(user.uid);

    if (userModel == null) {
      userModel = UserModel(
        id: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await db.createOrUpdateUser(userModel);
    }
    return userModel;
  }

  // Local mode
  final db = ref.read(localDatabaseServiceProvider);
  var userModel = await db.getUser(user.uid);
  if (userModel == null) {
    userModel = UserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    await db.createOrUpdateUser(userModel);
  }
  return userModel;
});

/// Wraps FirebaseDatabaseService to match LocalDatabaseService API.
class FirebaseDatabaseWrapper extends LocalDatabaseService {
  final DatabaseService _fb;

  FirebaseDatabaseWrapper(this._fb);

  @override
  Future<UserModel?> getUser(String userId) => _fb.getUser(userId);

  @override
  Future<void> createOrUpdateUser(UserModel user) =>
      _fb.createOrUpdateUser(user);

  @override
  Future<void> updateUser(String userId, Map<String, dynamic> data) =>
      _fb.updateUser(userId, data);

  @override
  Stream<List<ProfileModel>> profilesStream(String parentId) =>
      _fb.profilesStream(parentId);

  @override
  Future<ProfileModel> createProfile(ProfileModel profile) =>
      _fb.createProfile(profile);

  @override
  Future<void> updateProfile(ProfileModel profile) =>
      _fb.updateProfile(profile);

  @override
  Future<void> deleteProfile(String parentId, String profileId) =>
      _fb.deleteProfile(parentId, profileId);

  @override
  Future<void> updateProfileStats(
          String parentId, String profileId, ProfileStats stats) =>
      _fb.updateProfileStats(parentId, profileId, stats);

  @override
  Future<void> saveTest(TestModel test) => _fb.saveTest(test);

  @override
  Future<TestModel?> getTest(String testId) => _fb.getTest(testId);

  @override
  Future<TestModel?> getTestByShareCode(String shareCode) =>
      _fb.getTestByShareCode(shareCode);

  @override
  Future<void> saveAttempt(AttemptModel attempt) => _fb.saveAttempt(attempt);

  @override
  Stream<List<AttemptModel>> attemptsStream(
          String parentId, String profileId) =>
      _fb.attemptsStream(parentId, profileId);

  @override
  Future<List<AttemptModel>> getRecentAttempts(
          String parentId, String profileId,
          {int limit = 20}) =>
      _fb.getRecentAttempts(parentId, profileId, limit: limit);

  @override
  Future<List<AttemptModel>> getAttemptsForTest(
          String testId, String profileId) =>
      _fb.getAttemptsForTest(testId, profileId);
}

