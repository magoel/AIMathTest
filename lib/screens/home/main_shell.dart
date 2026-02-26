import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/feedback_button.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    '/home',
    '/new-test',
    '/progress',
    '/settings',
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t));
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => context.push('/select-profile'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (profile != null) ...[
                Text(profile.avatar, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(profile.name),
                const Icon(Icons.arrow_drop_down),
              ] else
                const Text('AIMathTest'),
            ],
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text('🧮', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
      body: Stack(
        children: [
          child,
          const FeedbackButton(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => context.go(_tabs[index]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'New Test'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
