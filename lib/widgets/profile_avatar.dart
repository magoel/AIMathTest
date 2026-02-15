import 'package:flutter/material.dart';
import '../models/profile_model.dart';

class ProfileAvatar extends StatelessWidget {
  final ProfileModel profile;
  final double size;
  final bool showName;
  final bool showGrade;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.profile,
    this.size = 48,
    this.showName = true,
    this.showGrade = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(size / 3),
            ),
            child: Center(
              child: Text(
                profile.avatar,
                style: TextStyle(fontSize: size * 0.5),
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(height: 4),
            Text(
              profile.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (showGrade) ...[
            Text(
              profile.gradeLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
