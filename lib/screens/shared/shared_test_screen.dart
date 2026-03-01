import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../../providers/test_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/app_button.dart';

class SharedTestScreen extends ConsumerStatefulWidget {
  final String shareCode;

  const SharedTestScreen({super.key, required this.shareCode});

  @override
  ConsumerState<SharedTestScreen> createState() => _SharedTestScreenState();
}

class _SharedTestScreenState extends ConsumerState<SharedTestScreen> {
  bool _loading = true;
  String? _error;
  String? _testId;

  @override
  void initState() {
    super.initState();
    _loadTest();
  }

  Future<void> _loadTest() async {
    try {
      final db = ref.read(databaseServiceProvider);
      final test = await db.getTestByShareCode(widget.shareCode);
      if (test == null) {
        setState(() {
          _error = 'Test not found. It may have expired.';
          _loading = false;
        });
        return;
      }
      ref.read(currentTestProvider.notifier).state = test;
      setState(() {
        _testId = test.id;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load test: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);

    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading test ${widget.shareCode}...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😕', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Go Home',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Test loaded — prompt to select profile and start
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/icon/app_icon.png', width: 80, height: 80),
              ),
              const SizedBox(height: 16),
              Text(
                'Shared Test',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Code: ${widget.shareCode}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              if (profile != null) ...[
                Text(
                  'Taking as ${profile.avatar} ${profile.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/select-profile'),
                  child: const Text('Switch profile'),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Start Test',
                  icon: Icons.rocket_launch,
                  onPressed: () => context.push('/test/$_testId'),
                ),
              ] else ...[
                const Text('Please create a profile first.'),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Go to Settings',
                  onPressed: () => context.go('/settings'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
