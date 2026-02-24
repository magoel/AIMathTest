import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/test_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/score_display.dart';
import '../../widgets/common/app_button.dart';

class OnboardingCompleteScreen extends ConsumerStatefulWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  ConsumerState<OnboardingCompleteScreen> createState() =>
      _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState
    extends ConsumerState<OnboardingCompleteScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    // Always celebrate on onboarding complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);
    final attemptsAsync = ref.watch(attemptsProvider);

    // Find latest attempt
    final attempts = attemptsAsync.valueOrNull ?? [];
    final latestAttempt = attempts.isNotEmpty ? attempts.first : null;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Text(
                    "You're all set!",
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (latestAttempt != null)
                    ScoreDisplay(
                      score: latestAttempt.score,
                      total: latestAttempt.totalQuestions,
                    ),
                  const SizedBox(height: 24),

                  if (profile != null)
                    Text(
                      'Great first test, ${profile.name}!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  const SizedBox(height: 24),

                  // Checklist
                  _CheckItem('Profile created'),
                  _CheckItem('First test completed'),
                  _CheckItem('Progress tracking started'),
                  const SizedBox(height: 24),

                  Text(
                    'You can now:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BulletItem('Take more tests'),
                  _BulletItem('Track progress over time'),
                  _BulletItem('Add more child profiles'),
                  const SizedBox(height: 32),

                  AppButton(
                    label: 'Go to Home',
                    icon: Icons.rocket_launch,
                    onPressed: () async {
                      // Mark onboarding as complete
                      final user = ref.read(authStateProvider).valueOrNull;
                      if (user != null) {
                        final db = ref.read(databaseServiceProvider);
                        await db.updateUser(user.uid, {
                          'onboardingCompleted': true,
                        });
                      }
                      if (context.mounted) context.go('/home');
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                maxBlastForce: 20,
                minBlastForce: 5,
                gravity: 0.2,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.orange,
                  Colors.purple,
                  Colors.pink,
                  Colors.yellow,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;
  const _CheckItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Text('•', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
