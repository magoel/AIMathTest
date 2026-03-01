import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      if (AppConfig.useFirebase) {
        await ref.read(firebaseAuthServiceProvider).signInWithGoogle();
      } else {
        await ref.read(localAuthServiceProvider).signInWithGoogle();
      }
    } catch (e, stackTrace) {
      developer.log('Sign-in failed', name: 'AIMathTest', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // App icon
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.tagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Feature highlights
              _FeatureRow(
                icon: Icons.auto_awesome,
                text: 'AI-powered personalized questions',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.trending_up,
                text: 'Track progress across topics',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.people,
                text: 'Multiple child profiles',
              ),
              const Spacer(),
              // Sign in button
              AppButton(
                label: 'Sign in with Google',
                icon: Icons.login,
                onPressed: _signIn,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              Text(
                'Free to use • No credit card required',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('${AppConstants.appUrl}/privacy.html'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  'Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
