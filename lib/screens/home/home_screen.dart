import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../../providers/test_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../config/constants.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _onboardingChecked = false;

  Future<void> _checkOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final currentProfiles = ref.read(profilesProvider).valueOrNull ?? [];
    if (currentProfiles.isEmpty) {
      _onboardingChecked = true;
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);
    final attemptsAsync = ref.watch(attemptsProvider);
    final profilesAsync = ref.watch(profilesProvider);

    // Show loading while profiles stream is connecting
    if (profilesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Only check onboarding once per session, and only after a real load
    final profiles = profilesAsync.valueOrNull ?? [];
    if (profiles.isEmpty && !_onboardingChecked) {
      // Wait a moment for the Firestore stream to deliver real data
      // before deciding to redirect to onboarding
      _checkOnboarding();
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            profile != null ? 'Hi ${profile.name}! Ready to practice?' : 'Welcome!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Start New Test button
          AppButton(
            label: 'Start New Test',
            icon: Icons.rocket_launch,
            onPressed: profile != null ? () => context.go('/new-test') : null,
          ),
          if (profile == null) ...[
            const SizedBox(height: 8),
            Text(
              'Create a child profile first in Settings',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
          const SizedBox(height: 28),

          // Recent Tests
          Text(
            'Recent Tests',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          attemptsAsync.when(
            data: (attempts) {
              if (attempts.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('📝', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text(
                            'No tests yet! Take your first test to see results here.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final recent = attempts.take(AppConstants.maxRecentTests).toList();
              return Column(
                children: recent.map((attempt) {
                  final topicLabels = attempt.testTopics
                      ?.map((t) => AppConstants.topics[t]?.label ?? t)
                      .join(', ') ?? 'Test';

                  return Card(
                    child: ListTile(
                      title: Text(topicLabels),
                      subtitle: Text(_timeAgo(attempt.completedAt)),
                      trailing: Text(
                        '${attempt.percentage.round()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: attempt.percentage >= 80
                              ? Colors.green
                              : attempt.percentage >= 60
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      onTap: () => context.push('/test/${attempt.testId}/results'),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading tests: $e'),
          ),

          const SizedBox(height: 20),

          // Streak
          if (profile?.stats.currentStreak != null && profile!.stats.currentStreak > 0)
            Card(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Text(
                      '${profile.stats.currentStreak}-day streak! Keep it up!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
