import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/test_model.dart';
import '../../models/attempt_model.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/test_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/number_pad.dart';

class TestTakingScreen extends ConsumerStatefulWidget {
  final String testId;
  final bool isOnboarding;

  const TestTakingScreen({
    super.key,
    required this.testId,
    this.isOnboarding = false,
  });

  @override
  ConsumerState<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends ConsumerState<TestTakingScreen> {
  TestModel? _test;
  int _currentIndex = 0;
  late List<String> _answers;
  late Stopwatch _stopwatch;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds = _stopwatch.elapsed.inSeconds);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _loadTest() {
    final currentTest = ref.read(currentTestProvider);
    if (currentTest != null && currentTest.id == widget.testId) {
      _test = currentTest;
      _answers = List.filled(_test!.questions.length, '');
    }
  }

  void _onKeyPressed(String key) {
    setState(() {
      _answers[_currentIndex] += key;
    });
  }

  void _onBackspace() {
    if (_answers[_currentIndex].isNotEmpty) {
      setState(() {
        _answers[_currentIndex] = _answers[_currentIndex]
            .substring(0, _answers[_currentIndex].length - 1);
      });
    }
  }

  Future<void> _submit() async {
    final unanswered = _answers.where((a) => a.isEmpty).length;
    if (unanswered > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Submit Test?'),
          content: Text('You have $unanswered unanswered question${unanswered > 1 ? 's' : ''}. Submit anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Working'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _submitting = true);
    _stopwatch.stop();

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      final profile = ref.read(activeProfileProvider);
      if (user == null || profile == null || _test == null) return;

      final answers = <AnswerModel>[];
      int score = 0;
      for (int i = 0; i < _test!.questions.length; i++) {
        final q = _test!.questions[i];
        final userAnswer = _answers[i].trim();
        final isCorrect = userAnswer.toLowerCase() == q.correctAnswer.toLowerCase();
        if (isCorrect) score++;
        answers.add(AnswerModel(
          questionId: q.id,
          userAnswer: userAnswer,
          isCorrect: isCorrect,
        ));
      }

      final attempt = AttemptModel(
        id: const Uuid().v4(),
        testId: _test!.id,
        parentId: user.uid,
        profileId: profile.id,
        answers: answers,
        score: score,
        totalQuestions: _test!.questions.length,
        percentage: (score / _test!.questions.length) * 100,
        timeTaken: _elapsedSeconds,
        shuffleOrder: List.generate(_test!.questions.length, (i) => i),
        completedAt: DateTime.now(),
        testTopics: _test!.config.topics,
      );

      final db = ref.read(databaseServiceProvider);
      await db.saveAttempt(attempt);

      // Update profile stats
      final recentAttempts = await db.getRecentAttempts(user.uid, profile.id);
      final totalTests = recentAttempts.length;
      final avgScore = totalTests > 0
          ? recentAttempts.map((a) => a.percentage).reduce((a, b) => a + b) / totalTests
          : 0.0;

      await db.updateProfileStats(
        user.uid,
        profile.id,
        ProfileStats(
          totalTests: totalTests,
          averageScore: avgScore,
          currentStreak: profile.stats.currentStreak + 1,
          lastTestAt: DateTime.now(),
        ),
      );

      if (mounted) {
        if (widget.isOnboarding) {
          context.go('/onboarding/complete');
        } else {
          context.go('/test/${_test!.id}/results');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_test == null) {
      _loadTest();
      if (_test == null) {
        return const Scaffold(
          body: Center(child: Text('Test not found')),
        );
      }
    }

    final question = _test!.questions[_currentIndex];
    final totalQuestions = _test!.questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave Test?'),
            content: const Text('Are you sure? Your progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Question ${_currentIndex + 1} of $totalQuestions'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.maybePop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _formatTime(_elapsedSeconds),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / totalQuestions,
              minHeight: 4,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Question card
                    Card(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          question.question,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Answer display
                    Text(
                      'Your Answer:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _answers[_currentIndex].isEmpty
                            ? ' '
                            : _answers[_currentIndex],
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Number pad
                    NumberPad(
                      onKeyPressed: _onKeyPressed,
                      onBackspace: _onBackspace,
                      showDecimal: _test!.config.topics.contains('decimals'),
                      showNegative: _test!.config.topics.contains('algebra'),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _currentIndex--),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  if (_currentIndex < totalQuestions - 1)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _currentIndex++),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: const Icon(Icons.check),
                        label: Text(_submitting ? 'Submitting...' : 'Submit'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

