import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class ScoreDisplay extends StatelessWidget {
  final int score;
  final int total;
  final double size;

  const ScoreDisplay({
    super.key,
    required this.score,
    required this.total,
    this.size = 120,
  });

  double get percentage => total > 0 ? (score / total) * 100 : 0;

  Color get _color {
    if (percentage >= 80) return AppTheme.success;
    if (percentage >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppConstants.scoreEmoji(percentage),
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(_color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score/$total',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${percentage.round()}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppConstants.scoreMessage(percentage),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
