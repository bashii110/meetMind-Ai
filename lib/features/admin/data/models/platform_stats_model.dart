import '../../domain/entities/platform_stats.dart';

class PlatformStatsModel extends PlatformStats {
  const PlatformStatsModel({
    required super.totalUsers,
    required super.activeUsers,
    required super.totalWorkspaces,
    required super.totalMeetings,
    required super.totalTasks,
    required super.storageUsedGb,
    required super.storageLimitGb,
  });

  factory PlatformStatsModel.fromJson(Map<String, dynamic> json) {
    return PlatformStatsModel(
      totalUsers: json['total_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      totalWorkspaces: json['total_workspaces'] as int? ?? 0,
      totalMeetings: json['total_meetings'] as int? ?? 0,
      totalTasks: json['total_tasks'] as int? ?? 0,
      storageUsedGb: (json['storage_used_gb'] as num?)?.toDouble() ?? 0,
      storageLimitGb: (json['storage_limit_gb'] as num?)?.toDouble() ?? 0,
    );
  }
}
