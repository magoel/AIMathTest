import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/test_provider.dart';
import '../../providers/user_provider.dart';
import '../../config/constants.dart';
import '../../config/board_curriculum.dart';
import '../../widgets/avatar_picker.dart';
import '../../widgets/upgrade_dialog.dart';
import '../../providers/subscription_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final authState = ref.watch(authStateProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Profiles section
          Text(
            'PROFILES',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),

          profilesAsync.when(
            data: (profiles) => Card(
              child: Column(
                children: [
                  ...profiles.map((profile) => ListTile(
                    leading: Text(profile.avatar, style: const TextStyle(fontSize: 28)),
                    title: Text(profile.name),
                    subtitle: Text('${AppConstants.gradeLabels[profile.grade]} \u2022 ${profile.boardLabel}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditProfileDialog(context, ref, profile),
                    ),
                  )),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: const Text('Add New Profile'),
                    onTap: () => context.push('/select-profile'),
                  ),
                ],
              ),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Switch Profile'),
              onTap: () => context.push('/select-profile'),
            ),
          ),

          const SizedBox(height: 24),

          // Account section
          Text(
            'ACCOUNT',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Signed in as'),
              subtitle: Text(authState.valueOrNull?.email ?? 'Unknown'),
            ),
          ),

          const SizedBox(height: 24),

          // Subscription section
          Text(
            'SUBSCRIPTION',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _SubscriptionCard(),

          const SizedBox(height: 24),

          // Legal section
          Text(
            'LEGAL',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => launchUrl(
                Uri.parse('https://aimathtest-kids-3ca24.web.app/privacy.html'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Sign out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out?'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  if (AppConfig.useFirebase) {
                    await ref.read(firebaseAuthServiceProvider).signOut();
                  } else {
                    await ref.read(localAuthServiceProvider).signOut();
                  }
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, ProfileModel profile) {
    showDialog(
      context: context,
      builder: (_) => _EditProfileDialog(ref: ref, profile: profile),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final WidgetRef ref;
  final ProfileModel profile;

  const _EditProfileDialog({required this.ref, required this.profile});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameController;
  late String _avatar;
  late int _grade;
  late String _board;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _avatar = widget.profile.avatar;
    _grade = widget.profile.grade;
    _board = widget.profile.board;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final db = widget.ref.read(databaseServiceProvider);
      await db.updateProfile(widget.profile.copyWith(
        name: _nameController.text.trim(),
        avatar: _avatar,
        grade: _grade,
        board: _board,
      ));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile?'),
        content: Text('Delete ${widget.profile.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = widget.ref.read(databaseServiceProvider);
      await db.deleteProfile(widget.profile.parentId, widget.profile.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Edit Profile'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose Avatar',
                  style: TextStyle(fontWeight: FontWeight.w600)),
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
                value: _grade,
                decoration: const InputDecoration(labelText: 'Grade Level'),
                items: List.generate(13, (i) {
                  return DropdownMenuItem(
                    value: i,
                    child: Text(AppConstants.gradeLabels[i]),
                  );
                }),
                onChanged: (v) => setState(() => _grade = v ?? _grade),
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
                onChanged: (v) => setState(() => _board = v ?? _board),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _delete,
          child: const Text('Delete',
              style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final userAsync = ref.watch(userProvider);
    final billingAvailable = ref.watch(billingAvailableProvider);
    final canUpgrade = billingAvailable.valueOrNull ?? false;

    if (isPremium) {
      final user = userAsync.valueOrNull;
      final isAnnual = user?.subscriptionPlan == 'premium_annual';
      return Card(
        color: Colors.amber.withOpacity(0.1),
        child: ListTile(
          leading: const Icon(Icons.diamond, color: Colors.amber),
          title: const Text('Premium Plan'),
          subtitle: Text(
            isAnnual
                ? 'Annual subscription \u2014 Unlimited tests!'
                : 'Monthly subscription \u2014 Unlimited tests!',
          ),
          trailing: TextButton(
            onPressed: () => launchUrl(
              Uri.parse(
                  'https://play.google.com/store/account/subscriptions'),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('Manage'),
          ),
        ),
      );
    }

    final monthUsed = ref.watch(monthGenerationCountProvider).valueOrNull ?? 0;
    final remaining = (AppConstants.freeTestMonthlyLimit - monthUsed)
        .clamp(0, AppConstants.freeTestMonthlyLimit);

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.diamond_outlined),
            title: const Text('Free Plan',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '$remaining of ${AppConstants.freeTestMonthlyLimit} test generations remaining this month',
            ),
          ),
          ListTile(
            dense: true,
            title: Text(
              'Upgrade to Premium for unlimited tests:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              '\u2022 Monthly: \u20B950/month\n'
              '\u2022 Annual: \u20B9500/year (save 17%)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          if (canUpgrade)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const UpgradeDialog(),
                  ),
                  icon: const Icon(Icons.star),
                  label: const Text('Upgrade to Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
