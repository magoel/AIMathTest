import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

final profilesProvider = StreamProvider<List<ProfileModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value([]);

  final db = ref.read(databaseServiceProvider);
  return db.profilesStream(user.uid);
});

final activeProfileIdProvider = StateProvider<String?>((ref) => null);

final activeProfileProvider = Provider<ProfileModel?>((ref) {
  final profiles = ref.watch(profilesProvider).valueOrNull ?? [];
  final activeId = ref.watch(activeProfileIdProvider);

  if (profiles.isEmpty) return null;
  if (activeId == null) return profiles.first;

  return profiles.where((p) => p.id == activeId).firstOrNull ?? profiles.first;
});
