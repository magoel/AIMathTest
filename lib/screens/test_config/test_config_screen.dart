import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/test_provider.dart';
import '../../providers/user_provider.dart';
import '../../config/constants.dart';
import '../../widgets/topic_chip.dart';
import '../../widgets/common/app_button.dart';

class TestConfigScreen extends ConsumerStatefulWidget {
  const TestConfigScreen({super.key});

  @override
  ConsumerState<TestConfigScreen> createState() => _TestConfigScreenState();
}

class _TestConfigScreenState extends ConsumerState<TestConfigScreen> {
  Set<String> _selectedTopics = {};
  int _difficulty = 5;
  int _questionCount = 10;
  bool _timed = false;
  bool _generating = false;

  Future<void> _startTest() async {
    if (_selectedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one topic')),
      );
      return;
    }

    setState(() => _generating = true);

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      final profile = ref.read(activeProfileProvider);
      if (user == null || profile == null) throw Exception('Not authenticated');

      final ai = ref.read(aiServiceProvider);
      final db = ref.read(databaseServiceProvider);

      final test = await ai.generateTest(
        parentId: user.uid,
        profileId: profile.id,
        profileName: profile.name,
        grade: profile.grade,
        topics: _selectedTopics.toList(),
        difficulty: _difficulty,
        questionCount: _questionCount,
        timed: _timed,
      );

      await db.saveTest(test);
      ref.read(currentTestProvider.notifier).state = test;

      if (mounted) context.push('/test/${test.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate test: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Your Test',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Topics
          Text(
            'Topics (select one or more)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TopicChipGrid(
            selected: _selectedTopics,
            onChanged: (s) => setState(() => _selectedTopics = s),
          ),
          const SizedBox(height: 24),

          // Difficulty
          Text(
            'Difficulty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('1'),
              Expanded(
                child: Slider(
                  value: _difficulty.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: 'Level $_difficulty',
                  onChanged: (v) => setState(() => _difficulty = v.round()),
                ),
              ),
              const Text('10'),
            ],
          ),
          Center(
            child: Text(
              'Level: $_difficulty',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Question count
          Text(
            'Questions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: AppConstants.questionCounts.map((count) {
              final isSelected = _questionCount == count;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$count'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _questionCount = count),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Timed mode
          SwitchListTile(
            title: const Text('Timed Mode'),
            subtitle: Text(
              _timed
                  ? '$_questionCount min time limit'
                  : 'No time limit',
            ),
            secondary: const Icon(Icons.timer),
            value: _timed,
            onChanged: (v) => setState(() => _timed = v),
          ),
          const SizedBox(height: 32),

          // Start button
          AppButton(
            label: 'Start Test',
            icon: Icons.rocket_launch,
            onPressed: _startTest,
            isLoading: _generating,
          ),
        ],
      ),
    );
  }
}
