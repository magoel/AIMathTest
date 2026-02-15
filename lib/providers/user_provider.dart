import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/local_database_service.dart';
import 'auth_provider.dart';

final databaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  final service = LocalDatabaseService();
  ref.onDispose(() => service.dispose());
  return service;
});

final userProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  final db = ref.read(databaseServiceProvider);
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
