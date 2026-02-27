import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/feedback_model.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/user_provider.dart';

/// Persistent "Feedback" tab on the right edge of the screen.
class FeedbackButton extends ConsumerWidget {
  const FeedbackButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      right: 0,
      top: MediaQuery.of(context).size.height * 0.45,
      child: GestureDetector(
        onTap: () => _showFeedbackDialog(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(-1, 1),
              ),
            ],
          ),
          child: const RotatedBox(
            quarterTurns: 3,
            child: Text(
              'Feedback',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, WidgetRef ref) {
    showFeedbackDialog(context, ref);
  }

  /// Open the feedback dialog from anywhere. Optional [initialMessage] pre-fills the text.
  static void showFeedbackDialog(BuildContext context, WidgetRef ref,
      {String? initialMessage}) {
    showDialog(
      context: context,
      builder: (_) =>
          _FeedbackDialog(ref: ref, initialMessage: initialMessage),
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  final WidgetRef ref;
  final String? initialMessage;
  const _FeedbackDialog({required this.ref, this.initialMessage});

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  late final _messageController = TextEditingController(
    text: widget.initialMessage,
  );
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final user = widget.ref.read(authStateProvider).valueOrNull;
      final profile = widget.ref.read(activeProfileProvider);
      if (user == null) return;

      final db = widget.ref.read(databaseServiceProvider);
      await db.saveFeedback(FeedbackModel(
        id: const Uuid().v4(),
        parentId: user.uid,
        profileId: profile?.id,
        message: _messageController.text.trim(),
        rating: _rating,
        screen: ModalRoute.of(context)?.settings.name ?? 'unknown',
        createdAt: DateTime.now(),
      ));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Feedback'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How would you rate your experience?'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starNum = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = starNum),
                  icon: Icon(
                    starNum <= _rating ? Icons.star : Icons.star_border,
                    color: starNum <= _rating ? Colors.amber : Colors.grey,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tell us what you think...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
