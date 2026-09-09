import 'package:flutter/material.dart';

/// SRD FR-2.5 / FR-13.1's "productivity" score, 0–100, rendered as a
/// simple ring gauge — deliberately a plain `CircularProgressIndicator`
/// rather than an fl_chart pie/donut, since a single-value ring doesn't
/// need a second charting API surface.
class ProductivityScoreGauge extends StatelessWidget {
  const ProductivityScoreGauge({super.key, required this.score});

  /// 0–100.
  final int score;

  Color _colorFor(BuildContext context) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 50) return const Color(0xFFFF9800);
    return Theme.of(context).colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context);
    final scheme = Theme.of(context).colorScheme;
    final clamped = score.clamp(0, 100);

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: clamped / 100,
              strokeWidth: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$clamped',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
              Text(
                'Productivity',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
