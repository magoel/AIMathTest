import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/constants.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/avatar_picker.dart';
import '../../widgets/common/app_button.dart';

class OnboardingProfileScreen extends ConsumerStatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  ConsumerState<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState
    extends ConsumerState<OnboardingProfileScreen> {
  final _nameController = TextEditingController();
  String _avatar = AppConstants.avatars.first;
  int _grade = 3;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      final db = ref.read(databaseServiceProvider);
      final profile = await db.createProfile(ProfileModel(
        id: '',
        parentId: user.uid,
        name: _nameController.text.trim(),
        avatar: _avatar,
        grade: _grade,
        createdAt: DateTime.now(),
      ));

      ref.read(activeProfileIdProvider.notifier).state = profile.id;

      if (mounted) context.go('/onboarding/config');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 1 of 3'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to AIMathTest!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Let's set up your child's profile",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Avatar
            const Text('Choose Avatar',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AvatarPicker(
              selected: _avatar,
              onChanged: (v) => setState(() => _avatar = v),
            ),
            const SizedBox(height: 24),

            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Child's Name"),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // Grade
            DropdownButtonFormField<int>(
              initialValue: _grade,
              decoration: const InputDecoration(labelText: 'Grade Level'),
              items: List.generate(13, (i) {
                return DropdownMenuItem(
                  value: i,
                  child: Text(AppConstants.gradeLabels[i]),
                );
              }),
              onChanged: (v) => setState(() => _grade = v ?? 3),
            ),
            const SizedBox(height: 32),

            AppButton(
              label: 'Continue',
              icon: Icons.arrow_forward,
              onPressed: _continue,
              isLoading: _saving,
            ),

            const SizedBox(height: 24),
            // Step indicator
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(true),
                  _dot(false),
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
