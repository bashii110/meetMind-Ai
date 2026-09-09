import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/analytics_summary.dart';

/// SRD FR-13.1: "meetings/month" chart.
class MeetingsPerMonthChart extends StatelessWidget {
  const MeetingsPerMonthChart({super.key, required this.data});

  final List<MonthlyMeetingCount> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No meeting data yet.')),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final maxCount = data.map((d) => d.count).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxCount == 0 ? 1 : maxCount) * 1.25;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY.toDouble(),
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value != value.roundToDouble()) return const SizedBox.shrink();
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data[index].monthLabel,
                      style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].count.toDouble(),
                    color: scheme.primary,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
