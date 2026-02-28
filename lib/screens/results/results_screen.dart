import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/constants.dart';
import '../../models/test_model.dart';
import '../../providers/test_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/score_display.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/math_text.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final String testId;

  const ResultsScreen({super.key, required this.testId});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  TestModel? _test;
  bool _loading = true;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _maybePlayConfetti(double percentage) {
    if (percentage >= 80) {
      _confettiController.play();
    }
  }

  Future<void> _loadData() async {
    // Try current test first
    final currentTest = ref.read(currentTestProvider);
    if (currentTest != null && currentTest.id == widget.testId) {
      setState(() {
        _test = currentTest;
        _loading = false;
      });
      return;
    }

    // Load from database
    try {
      final db = ref.read(databaseServiceProvider);
      final test = await db.getTest(widget.testId);
      if (mounted) {
        setState(() {
          _test = test;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attemptsAsync = ref.watch(attemptsProvider);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_test == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Test not found')),
      );
    }

    // Find the latest attempt for this test
    final attempts = attemptsAsync.valueOrNull ?? [];
    final attempt = attempts.where((a) => a.testId == widget.testId).firstOrNull;

    // Trigger confetti on first load
    if (attempt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybePlayConfetti(attempt.percentage);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (attempt != null) ...[
              ScoreDisplay(
                score: attempt.score,
                total: attempt.totalQuestions,
              ),
              const SizedBox(height: 8),
              if (attempt.timeTaken > 0)
                Text(
                  'Time: ${attempt.timeTaken ~/ 60}:${(attempt.timeTaken % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(height: 24),

              // Question review
              ...List.generate(_test!.questions.length, (i) {
                final q = _test!.questions[i];
                final answer = i < attempt.answers.length
                    ? attempt.answers[i]
                    : null;
                final isCorrect = answer?.isCorrect ?? false;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MathText(
                                q.question,
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.left,
                              ),
                              if (answer != null && !isCorrect) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('Your answer: ',
                                        style: TextStyle(color: Colors.red)),
                                    Expanded(
                                      child: MathText(
                                        answer.userAnswer,
                                        style: const TextStyle(color: Colors.red),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (!isCorrect) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Text('Correct: ',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        )),
                                    Expanded(
                                      child: MathText(
                                        q.correctAnswer,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else ...[
              const Text('No attempt found for this test'),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Share',
                    icon: Icons.share,
                    isOutlined: true,
                    onPressed: () {
                      final url = '${AppConstants.appUrl}/shared/${_test!.shareCode}';
                      Share.share('Try this math test!\n$url');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Re-take',
                    icon: Icons.refresh,
                    isOutlined: true,
                    onPressed: () {
                      ref.read(currentTestProvider.notifier).state = _test;
                      ref.read(retakeAttemptIdProvider.notifier).state = attempt?.id;
                      context.push('/test/${_test!.id}');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Back to Home',
              icon: Icons.home,
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // downward
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
    );
  }
}
