import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class ScoreDisplay extends StatefulWidget {
  final int score;
  final int total;
  final double size;

  const ScoreDisplay({
    super.key,
    required this.score,
    required this.total,
    this.size = 120,
  });

  @override
  State<ScoreDisplay> createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends State<ScoreDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;
  late Animation<int> _scoreAnim;
  late Animation<double> _fadeAnim;

  double get percentage =>
      widget.total > 0 ? (widget.score / widget.total) * 100 : 0;

  Color get _color {
    if (percentage >= 80) return AppTheme.success;
    if (percentage >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressAnim = Tween<double>(begin: 0, end: percentage / 100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scoreAnim = IntTween(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animatedPercentage =
            widget.total > 0 ? (_scoreAnim.value / widget.total) * 100 : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                AppConstants.scoreEmoji(percentage),
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      value: _progressAnim.value,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(_color),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_scoreAnim.value}/${widget.total}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${animatedPercentage.round()}%',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
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
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                AppConstants.scoreMessage(percentage),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
