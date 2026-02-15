import 'package:flutter/material.dart';
import '../config/constants.dart';

class AvatarPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const AvatarPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppConstants.avatars.map((avatar) {
        final isSelected = avatar == selected;
        return GestureDetector(
          onTap: () => onChanged(avatar),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(avatar, style: const TextStyle(fontSize: 28)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
