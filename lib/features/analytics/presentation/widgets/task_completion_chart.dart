import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../domain/entities/analytics_summary.dart';

/// SRD FR-13.1: "completed tasks" and "pending tasks" charts, combined
/// into one donut with a status breakdown legend rather than two
/// separate charts.
class TaskCompletionChart extends StatelessWidget {
  const TaskCompletionChart({super.key, required this.stats});

  final TaskCompletionStats stats;

  static const _colors = {
    'Completed': Color(0xFF4CAF50),
    'In progress': Color(0xFF2196F3),
    'Pending': Color(0xFFFF9800),
    'Cancelled': Color(0xFF9E9E9E),
  };

  @override
  Widget build(BuildContext context) {
    if (stats.total == 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No task data yet.')),
      );
    }

    final counts = {
      'Completed': stats.completed,
      'In progress': stats.inProgress,
      'Pending': stats.pending,
      'Cancelled': stats.cancelled,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (final entry in counts.entries)
                  if (entry.value > 0)
                    PieChartSectionData(
                      value: entry.value.toDouble(),
                      color: _colors[entry.key],
                      title: '${entry.value}',
                      radius: 46,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(width: Spacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in counts.entries)
                if (entry.value > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: _colors[entry.key], shape: BoxShape.circle),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            '${entry.key} (${entry.value})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
