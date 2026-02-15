import 'package:flutter/material.dart';
import '../config/constants.dart';

class TopicChipGrid extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const TopicChipGrid({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.topics.entries.map((entry) {
        final isSelected = selected.contains(entry.key);
        return GestureDetector(
          onTap: () {
            final newSet = Set<String>.from(selected);
            if (isSelected) {
              newSet.remove(entry.key);
            } else {
              newSet.add(entry.key);
            }
            onChanged(newSet);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.value.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.white, size: 16),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
