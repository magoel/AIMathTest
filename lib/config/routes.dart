import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/landing/landing_screen.dart';
import '../screens/onboarding/onboarding_profile_screen.dart';
import '../screens/onboarding/onboarding_config_screen.dart';
import '../screens/onboarding/onboarding_complete_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/test_config/test_config_screen.dart';
import '../screens/test_taking/test_taking_screen.dart';
import '../screens/results/results_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_selector_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/shared/shared_test_screen.dart';

/// Notifier that triggers GoRouter redirect re-evaluation
/// without recreating the entire router.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (prev, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Read current values (not watch — we use refreshListenable instead)
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthLoading = authState.isLoading;
      final location = state.matchedLocation;

      if (isAuthLoading) return null;

      // Not logged in → landing page (except allow shared links)
      if (!isLoggedIn) {
        if (location != '/') return '/';
        return null;
      }

      // Logged in, on landing page → always go to home
      if (location == '/') return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/select-profile',
        builder: (context, state) => const ProfileSelectorScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/config',
        builder: (context, state) => const OnboardingConfigScreen(),
      ),
      GoRoute(
        path: '/onboarding/complete',
        builder: (context, state) => const OnboardingCompleteScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/new-test',
            builder: (context, state) => const TestConfigScreen(),
          ),
          GoRoute(
            path: '/progress',
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/shared/:shareCode',
        builder: (context, state) => SharedTestScreen(
          shareCode: state.pathParameters['shareCode']!,
        ),
      ),
      GoRoute(
        path: '/onboarding/test/:testId',
        builder: (context, state) => TestTakingScreen(
          testId: state.pathParameters['testId']!,
          isOnboarding: true,
        ),
      ),
      GoRoute(
        path: '/test/:testId',
        builder: (context, state) => TestTakingScreen(
          testId: state.pathParameters['testId']!,
        ),
      ),
      GoRoute(
        path: '/test/:testId/results',
        builder: (context, state) => ResultsScreen(
          testId: state.pathParameters['testId']!,
        ),
      ),
    ],
  );
});
