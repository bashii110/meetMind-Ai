import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import 'glass_card.dart';

/// A short list of heuristic tips (core/insights/productivity_tips.dart)
/// shown on the dashboard — the "productivity recommendations" bonus
/// feature. Renders nothing when there are no tips, same "quietly
/// disappears" convention every other optional dashboard section uses.
class ProductivityTipsCard extends StatelessWidget {
  const ProductivityTipsCard({super.key, required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 18, color: scheme.tertiary),
              const SizedBox(width: Spacing.xs),
              Text(
                'For you',
                style: TextStyle(color: scheme.tertiary, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Text(tip, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
