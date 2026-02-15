import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../../providers/test_provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final attemptsAsync = ref.watch(attemptsProvider);

    if (profile == null) {
      return const Center(child: Text('Select a profile first'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${profile.name}'s Progress",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Overall stats
          Row(
            children: [
              _StatCard(
                label: 'Average',
                value: '${profile.stats.averageScore.round()}%',
                icon: Icons.trending_up,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Tests',
                value: '${profile.stats.totalTests}',
                icon: Icons.assignment,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Streak',
                value: '${profile.stats.currentStreak}',
                icon: Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Performance by topic
          Text(
            'Performance by Topic',
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
                      child: Text(
                        'Take some tests to see your progress here!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Calculate per-topic scores from attempt answers
              final topicAvg = <String, double>{};
              final topicCounts = <String, int>{};
              for (final attempt in attempts) {
                // Use testTopics if available
                if (attempt.testTopics != null && attempt.testTopics!.isNotEmpty) {
                  for (final topic in attempt.testTopics!) {
                    topicAvg[topic] = (topicAvg[topic] ?? 0) + attempt.percentage;
                    topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
                  }
                } else {
                  // Fallback: count as "general" so tests still appear
                  topicAvg['general'] = (topicAvg['general'] ?? 0) + attempt.percentage;
                  topicCounts['general'] = (topicCounts['general'] ?? 0) + 1;
                }
              }
              for (final topic in topicAvg.keys.toList()) {
                topicAvg[topic] = topicAvg[topic]! / topicCounts[topic]!;
              }
              // Remove the fallback "general" bucket if real topics exist
              if (topicAvg.length > 1) topicAvg.remove('general');
              topicCounts.remove('general');

              if (topicAvg.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No topic data yet'),
                  ),
                );
              }

              // Find weakest topic
              String? weakestTopic;
              double weakestScore = 100;
              for (final entry in topicAvg.entries) {
                if (entry.value < weakestScore) {
                  weakestScore = entry.value;
                  weakestTopic = entry.key;
                }
              }

              return Column(
                children: [
                  ...topicAvg.entries.map((entry) {
                    final info = AppConstants.topics[entry.key];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TopicBar(
                        label: info?.label ?? entry.key,
                        icon: info?.icon ?? '?',
                        percentage: entry.value,
                      ),
                    );
                  }),
                  if (weakestTopic != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: AppTheme.warning.withOpacity(0.1),
                      child: ListTile(
                        leading: const Text('💡', style: TextStyle(fontSize: 24)),
                        title: Text(
                          'Focus Area: ${AppConstants.topics[weakestTopic]?.label ?? weakestTopic}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('Practice this topic to improve!'),
                        onTap: () => context.go('/new-test'),
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 24),

          // Test history
          Text(
            'Test History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          attemptsAsync.when(
            data: (attempts) {
              if (attempts.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No tests taken yet'),
                  ),
                );
              }

              return Column(
                children: attempts.map((attempt) {
                  final topics = attempt.testTopics
                      ?.map((t) => AppConstants.topics[t]?.label ?? t)
                      .join(', ') ?? 'Test';

                  return Card(
                    child: ListTile(
                      title: Text(topics),
                      subtitle: Text(
                        '${attempt.completedAt.month}/${attempt.completedAt.day}/${attempt.completedAt.year}',
                      ),
                      trailing: Text(
                        '${attempt.percentage.round()}%',
                        style: TextStyle(
                          fontSize: 16,
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
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicBar extends StatelessWidget {
  final String label;
  final String icon;
  final double percentage;

  const _TopicBar({
    required this.label,
    required this.icon,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text('$icon $label', style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 20,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                percentage >= 80
                    ? AppTheme.success
                    : percentage >= 60
                        ? AppTheme.warning
                        : AppTheme.error,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${percentage.round()}%',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
