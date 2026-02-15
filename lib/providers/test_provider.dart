import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/test_model.dart';
import '../models/attempt_model.dart';
import '../services/ai_service.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';
import 'user_provider.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

final currentTestProvider = StateProvider<TestModel?>((ref) => null);

final testGenerationProvider = FutureProvider.family<TestModel, TestConfig>(
  (ref, config) async {
    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) throw Exception('Not authenticated');

    final profile = ref.read(activeProfileProvider);
    if (profile == null) throw Exception('No active profile');

    final ai = ref.read(aiServiceProvider);
    final db = ref.read(databaseServiceProvider);

    final test = await ai.generateTest(
      parentId: user.uid,
      profileId: profile.id,
      profileName: profile.name,
      grade: profile.grade,
      topics: config.topics,
      difficulty: config.difficulty,
      questionCount: config.questionCount,
      timed: config.timed,
    );

    await db.saveTest(test);
    return test;
  },
);

final attemptsProvider = StreamProvider<List<AttemptModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  final profile = ref.watch(activeProfileProvider);

  if (user == null || profile == null) return Stream.value([]);

  final db = ref.read(databaseServiceProvider);
  return db.attemptsStream(user.uid, profile.id);
});
