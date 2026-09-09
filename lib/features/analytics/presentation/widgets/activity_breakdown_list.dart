import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../domain/entities/analytics_summary.dart';

/// SRD FR-13.1's "department/user activity" — a simple ranked bar list
/// (rather than another fl_chart type) since it's really just "top N,
/// each proportional to the max," which a `LinearProgressIndicator` per
/// row conveys clearly without a second charting API surface.
class ActivityBreakdownList extends StatelessWidget {
  const ActivityBreakdownList({super.key, required this.entries, this.emptyLabel = 'No activity yet.'});

  final List<ActivityBreakdownEntry> entries;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Text(emptyLabel, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    final sorted = [...entries]..sort((a, b) => b.count.compareTo(a.count));
    final maxCount = sorted.first.count == 0 ? 1 : sorted.first.count;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (final entry in sorted)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('${entry.count}', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.count / maxCount,
                    minHeight: 6,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
