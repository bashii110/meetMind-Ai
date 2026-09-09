import 'package:equatable/equatable.dart';

/// SRD FR-13.1: "charts for meetings/month, completed tasks, average
/// meeting duration, pending tasks, productivity, time spent, and
/// department/user activity." One month's meeting count for the
/// meetings-per-month bar chart.
class MonthlyMeetingCount extends Equatable {
  const MonthlyMeetingCount({required this.monthLabel, required this.count});

  /// Short display label, e.g. "Jan", "Feb" — the backend controls
  /// ordering and range (typically the trailing 6–12 months).
  final String monthLabel;
  final int count;

  @override
  List<Object?> get props => [monthLabel, count];
}

/// Breakdown of tasks by status within the analytics window — backs both
/// the "completed tasks" and "pending tasks" chart requirements from a
/// single donut chart rather than two separate ones.
class TaskCompletionStats extends Equatable {
  const TaskCompletionStats({
    required this.completed,
    required this.pending,
    required this.inProgress,
    required this.cancelled,
  });

  final int completed;
  final int pending;
  final int inProgress;
  final int cancelled;

  int get total => completed + pending + inProgress + cancelled;

  double get completionRate => total == 0 ? 0 : completed / total;

  @override
  List<Object?> get props => [completed, pending, inProgress, cancelled];
}

/// One row in a department- or user-activity breakdown (SRD FR-13.1's
/// "department/user activity") — kept generic so the same widget
/// (`ActivityBreakdownList`) renders both.
class ActivityBreakdownEntry extends Equatable {
  const ActivityBreakdownEntry({required this.label, required this.count});

  final String label;
  final int count;

  @override
  List<Object?> get props => [label, count];
}

/// Aggregated analytics for one workspace — see ARCHITECTURE.md's
/// documented `GET /workspaces/{id}/analytics` endpoint. Every number
/// here is pre-computed server-side (cached in Redis per ARCHITECTURE.md
/// section 3.5) rather than derived client-side from raw meeting/task
/// lists, since the same aggregation needs to stay consistent wherever
/// it's shown (e.g. a future PDF export in Phase 12).
class AnalyticsSummary extends Equatable {
  const AnalyticsSummary({
    required this.workspaceId,
    required this.meetingsPerMonth,
    required this.taskCompletion,
    required this.avgMeetingDurationMinutes,
    required this.productivityScore,
    required this.totalTimeSpentHours,
    required this.activeUserCount,
    required this.departmentActivity,
    required this.userActivity,
  });

  final String workspaceId;
  final List<MonthlyMeetingCount> meetingsPerMonth;
  final TaskCompletionStats taskCompletion;
  final double avgMeetingDurationMinutes;

  /// 0–100, per SRD FR-2.5 / FR-13.1's "productivity" chart.
  final int productivityScore;
  final double totalTimeSpentHours;
  final int activeUserCount;
  final List<ActivityBreakdownEntry> departmentActivity;
  final List<ActivityBreakdownEntry> userActivity;

  @override
  List<Object?> get props => [
        workspaceId,
        meetingsPerMonth,
        taskCompletion,
        avgMeetingDurationMinutes,
        productivityScore,
        totalTimeSpentHours,
        activeUserCount,
        departmentActivity,
        userActivity,
      ];
}
