import '../../domain/entities/analytics_summary.dart';

class AnalyticsSummaryModel extends AnalyticsSummary {
  const AnalyticsSummaryModel({
    required super.workspaceId,
    required super.meetingsPerMonth,
    required super.taskCompletion,
    required super.avgMeetingDurationMinutes,
    required super.productivityScore,
    required super.totalTimeSpentHours,
    required super.activeUserCount,
    required super.departmentActivity,
    required super.userActivity,
  });

  factory AnalyticsSummaryModel.fromJson(String workspaceId, Map<String, dynamic> json) {
    final meetingsPerMonth = (json['meetings_per_month'] as List? ?? const [])
        .map((e) => MonthlyMeetingCount(
              monthLabel: (e as Map<String, dynamic>)['month'] as String? ?? '',
              count: e['count'] as int? ?? 0,
            ))
        .toList();

    final taskCompletionJson = json['task_completion'] as Map<String, dynamic>? ?? const {};
    final taskCompletion = TaskCompletionStats(
      completed: taskCompletionJson['completed'] as int? ?? 0,
      pending: taskCompletionJson['pending'] as int? ?? 0,
      inProgress: taskCompletionJson['in_progress'] as int? ?? 0,
      cancelled: taskCompletionJson['cancelled'] as int? ?? 0,
    );

    List<ActivityBreakdownEntry> parseBreakdown(String key) {
      return (json[key] as List? ?? const [])
          .map((e) => ActivityBreakdownEntry(
                label: (e as Map<String, dynamic>)['label'] as String? ?? '',
                count: e['count'] as int? ?? 0,
              ))
          .toList();
    }

    return AnalyticsSummaryModel(
      workspaceId: workspaceId,
      meetingsPerMonth: meetingsPerMonth,
      taskCompletion: taskCompletion,
      avgMeetingDurationMinutes: (json['avg_meeting_duration_minutes'] as num?)?.toDouble() ?? 0,
      productivityScore: json['productivity_score'] as int? ?? 0,
      totalTimeSpentHours: (json['total_time_spent_hours'] as num?)?.toDouble() ?? 0,
      activeUserCount: json['active_user_count'] as int? ?? 0,
      departmentActivity: parseBreakdown('department_activity'),
      userActivity: parseBreakdown('user_activity'),
    );
  }
}
