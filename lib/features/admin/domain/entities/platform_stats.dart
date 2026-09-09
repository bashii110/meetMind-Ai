import 'package:equatable/equatable.dart';

/// SRD FR-16.2: "Admins shall view platform analytics and storage
/// usage." Platform-wide (not workspace-scoped, unlike the `analytics`
/// feature) — backs the Admin screen's Overview tab.
class PlatformStats extends Equatable {
  const PlatformStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalWorkspaces,
    required this.totalMeetings,
    required this.totalTasks,
    required this.storageUsedGb,
    required this.storageLimitGb,
  });

  final int totalUsers;
  final int activeUsers;
  final int totalWorkspaces;
  final int totalMeetings;
  final int totalTasks;
  final double storageUsedGb;
  final double storageLimitGb;

  double get storageUsageRatio => storageLimitGb == 0 ? 0 : (storageUsedGb / storageLimitGb).clamp(0, 1);

  @override
  List<Object?> get props =>
      [totalUsers, activeUsers, totalWorkspaces, totalMeetings, totalTasks, storageUsedGb, storageLimitGb];
}
