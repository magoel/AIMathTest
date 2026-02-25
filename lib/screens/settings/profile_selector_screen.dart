import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/profile_avatar.dart';
import '../../config/constants.dart';
import '../../config/board_curriculum.dart';
import '../../widgets/avatar_picker.dart';

class ProfileSelectorScreen extends ConsumerWidget {
  const ProfileSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                "Who's practicing today?",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: profilesAsync.when(
                  data: (profiles) => _buildProfileGrid(context, ref, profiles),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileGrid(
    BuildContext context,
    WidgetRef ref,
    List<ProfileModel> profiles,
  ) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.8,
      children: [
        ...profiles.map((profile) => _ProfileCard(
          profile: profile,
          onTap: () {
            ref.read(activeProfileIdProvider.notifier).state = profile.id;
            context.go('/home');
          },
        )),
        _AddProfileCard(onTap: () => _showAddProfileDialog(context, ref)),
      ],
    );
  }

  void _showAddProfileDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _AddProfileDialog(ref: ref),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onTap;

  const _ProfileCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ProfileAvatar(
            profile: profile,
            size: 64,
            showGrade: true,
          ),
        ),
      ),
    );
  }
}

class _AddProfileCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(21),
              ),
              child: const Icon(Icons.add, size: 32, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProfileDialog extends StatefulWidget {
  final WidgetRef ref;

  const _AddProfileDialog({required this.ref});

  @override
  State<_AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends State<_AddProfileDialog> {
  final _nameController = TextEditingController();
  String _avatar = AppConstants.avatars.first;
  int _grade = 3;
  String _board = 'cbse';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      final user = widget.ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      final db = widget.ref.read(databaseServiceProvider);
      await db.createProfile(ProfileModel(
        id: '',
        parentId: user.uid,
        name: _nameController.text.trim(),
        avatar: _avatar,
        grade: _grade,
        board: _board,
        createdAt: DateTime.now(),
      ));

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Avatar'),
            const SizedBox(height: 8),
            AvatarPicker(
              selected: _avatar,
              onChanged: (v) => setState(() => _avatar = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Child's Name"),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _board,
              decoration: const InputDecoration(labelText: 'Curriculum Board'),
              items: Board.values.map((board) {
                return DropdownMenuItem(
                  value: board.name,
                  child: Text(board.label),
                );
              }).toList(),
              onChanged: (v) => setState(() => _board = v ?? 'cbse'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
