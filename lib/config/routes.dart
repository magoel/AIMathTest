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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoading = authState.isLoading;
      final location = state.matchedLocation;

      if (isLoading) return null;

      if (!isLoggedIn) {
        if (location != '/') return '/';
        return null;
      }

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
