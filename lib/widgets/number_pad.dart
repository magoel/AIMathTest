import 'package:flutter/material.dart';

class NumberPad extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onBackspace;
  final bool showDecimal;
  final bool showNegative;

  const NumberPad({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    this.showDecimal = true,
    this.showNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 8),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 8),
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 8),
        _buildRow([
          showNegative ? '-' : '',
          '0',
          showDecimal ? '.' : '',
        ]),
        const SizedBox(height: 8),
        _buildBackspaceRow(),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 72, height: 56);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _NumberKey(
            label: key,
            onTap: () => onKeyPressed(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBackspaceRow() {
    return Center(
      child: SizedBox(
        width: 160,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: onBackspace,
          icon: const Icon(Icons.backspace_outlined, size: 20),
          label: const Text('Delete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black87,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NumberKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 72,
          height: 56,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
