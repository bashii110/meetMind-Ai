import 'package:flutter/material.dart';

import '../insights/meeting_score.dart';
import '../theme/spacing.dart';
import 'glass_card.dart';

/// Renders a [MeetingScore] as a small glass-card badge — the numeric
/// score plus a qualitative label. Tapping it reveals the factors that
/// produced the score, kept out of the way by default so it doesn't
/// compete with the summary content it sits next to.
class MeetingScoreBadge extends StatelessWidget {
  const MeetingScoreBadge({super.key, required this.score});

  final MeetingScore score;

  Color _colorFor(ColorScheme scheme) {
    if (score.value >= 80) return const Color(0xFF4CAF50);
    if (score.value >= 60) return scheme.tertiary;
    if (score.value >= 40) return const Color(0xFFFF9800);
    return scheme.error;
  }

  void _showFactors(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How this score was calculated', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Spacing.md),
              for (final factor in score.factors)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(factor)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _colorFor(scheme);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      child: InkWell(
        onTap: () => _showFactors(context),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 16, color: color),
            const SizedBox(width: Spacing.xs),
            Text('${score.value}', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 16)),
            const SizedBox(width: 4),
            Text(score.label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(width: 4),
            Icon(Icons.info_outline, size: 14, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
