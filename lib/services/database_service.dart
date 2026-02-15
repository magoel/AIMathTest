import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../models/test_model.dart';
import '../models/attempt_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ──

  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> createOrUpdateUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(
      user.toFirestore(),
      SetOptions(merge: true),
    );
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  // ── Profiles ──

  Stream<List<ProfileModel>> profilesStream(String parentId) {
    return _db
        .collection('users')
        .doc(parentId)
        .collection('profiles')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProfileModel.fromFirestore(doc, parentId))
            .toList());
  }

  Future<ProfileModel> createProfile(ProfileModel profile) async {
    final docRef = await _db
        .collection('users')
        .doc(profile.parentId)
        .collection('profiles')
        .add(profile.toFirestore());
    final doc = await docRef.get();
    return ProfileModel.fromFirestore(doc, profile.parentId);
  }

  Future<void> updateProfile(ProfileModel profile) async {
    await _db
        .collection('users')
        .doc(profile.parentId)
        .collection('profiles')
        .doc(profile.id)
        .update(profile.toFirestore());
  }

  Future<void> deleteProfile(String parentId, String profileId) async {
    await _db
        .collection('users')
        .doc(parentId)
        .collection('profiles')
        .doc(profileId)
        .delete();
  }

  Future<void> updateProfileStats(
    String parentId,
    String profileId,
    ProfileStats stats,
  ) async {
    await _db
        .collection('users')
        .doc(parentId)
        .collection('profiles')
        .doc(profileId)
        .update({'stats': stats.toMap()});
  }

  // ── Tests ──

  Future<void> saveTest(TestModel test) async {
    await _db.collection('tests').doc(test.id).set(test.toFirestore());
  }

  Future<TestModel?> getTest(String testId) async {
    final doc = await _db.collection('tests').doc(testId).get();
    if (!doc.exists) return null;
    return TestModel.fromFirestore(doc);
  }

  Future<TestModel?> getTestByShareCode(String shareCode) async {
    final snapshot = await _db
        .collection('tests')
        .where('shareCode', isEqualTo: shareCode)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return TestModel.fromFirestore(snapshot.docs.first);
  }

  // ── Attempts ──

  Future<void> saveAttempt(AttemptModel attempt) async {
    await _db.collection('attempts').doc(attempt.id).set(attempt.toFirestore());
  }

  Stream<List<AttemptModel>> attemptsStream(String parentId, String profileId) {
    return _db
        .collection('attempts')
        .where('parentId', isEqualTo: parentId)
        .where('profileId', isEqualTo: profileId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AttemptModel.fromFirestore(doc)).toList());
  }

  Future<List<AttemptModel>> getRecentAttempts(
    String parentId,
    String profileId, {
    int limit = 20,
  }) async {
    final snapshot = await _db
        .collection('attempts')
        .where('parentId', isEqualTo: parentId)
        .where('profileId', isEqualTo: profileId)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => AttemptModel.fromFirestore(doc))
        .toList();
  }

  Future<List<AttemptModel>> getAttemptsForTest(
    String testId,
    String profileId,
  ) async {
    final snapshot = await _db
        .collection('attempts')
        .where('testId', isEqualTo: testId)
        .where('profileId', isEqualTo: profileId)
        .orderBy('completedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => AttemptModel.fromFirestore(doc))
        .toList();
  }
}
