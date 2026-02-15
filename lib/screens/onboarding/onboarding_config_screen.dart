import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_config.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/test_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/topic_chip.dart';
import '../../widgets/common/app_button.dart';

class OnboardingConfigScreen extends ConsumerStatefulWidget {
  const OnboardingConfigScreen({super.key});

  @override
  ConsumerState<OnboardingConfigScreen> createState() =>
      _OnboardingConfigScreenState();
}

class _OnboardingConfigScreenState
    extends ConsumerState<OnboardingConfigScreen> {
  Set<String> _selectedTopics = {'addition'};
  int _difficulty = 3;
  int _questionCount = 5;
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
      if (user == null || profile == null) throw Exception('Not set up');

      // Set difficulty based on grade
      _difficulty = (profile.grade).clamp(1, 10);

      final ai = ref.read(aiServiceProvider);

      final test = await ai.generateTest(
        parentId: user.uid,
        profileId: profile.id,
        profileName: profile.name,
        grade: profile.grade,
        topics: _selectedTopics.toList(),
        difficulty: _difficulty,
        questionCount: _questionCount,
        timed: false,
      );

      if (!AppConfig.useFirebase) {
        final db = ref.read(databaseServiceProvider);
        await db.saveTest(test);
      }
      ref.read(currentTestProvider.notifier).state = test;

      if (mounted) context.push('/onboarding/test/${test.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 2 of 3'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Let's create ${profile?.name ?? 'your'}'s first test!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick topics (we suggest starting with 1-2 topics)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            TopicChipGrid(
              selected: _selectedTopics,
              onChanged: (s) => setState(() => _selectedTopics = s),
            ),
            const SizedBox(height: 24),

            // Difficulty
            Text(
              'Difficulty (recommended: Level ${(profile?.grade ?? 3).clamp(1, 10)})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _difficulty.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: 'Level $_difficulty',
              onChanged: (v) => setState(() => _difficulty = v.round()),
            ),
            const SizedBox(height: 16),

            // Questions
            const Text('Questions',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: AppConstants.questionCounts.map((count) {
                final isSelected = _questionCount == count;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('$count'),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _questionCount = count),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_questionCount == 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '5 is great for a first test!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 32),

            AppButton(
              label: 'Start Test',
              icon: Icons.rocket_launch,
              onPressed: _startTest,
              isLoading: _generating,
            ),

            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(true),
                  _dot(true),
                  _dot(false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade300,
      ),
    );
  }
}
