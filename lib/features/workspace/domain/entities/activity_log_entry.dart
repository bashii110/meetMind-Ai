import 'package:equatable/equatable.dart';

/// SRD FR-10.4 / ARCHITECTURE.md `activity_logs` table. `subjectType` and
/// `subjectId` point at whatever the action was about (a meeting, a task,
/// a member...) — kept as loose strings rather than a closed enum since
/// the backend logs many different action types this entity doesn't need
/// to enumerate (mirrors how `AppNotificationEntity` treats `payload`).
class ActivityLogEntry extends Equatable {
  const ActivityLogEntry({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.createdAt,
    this.userAvatar,
    this.subjectType,
    this.subjectId,
    this.description,
  });

  final String id;
  final String workspaceId;
  final String userId;
  final String userName;
  final String? userAvatar;

  /// e.g. `meeting_created`, `task_assigned`, `member_invited`.
  final String action;
  final String? subjectType;
  final String? subjectId;

  /// Human-readable line, e.g. "invited jane@doe.com" — preferred over
  /// building sentences client-side from [action] since the backend knows
  /// the full context of each logged event.
  final String? description;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        userId,
        userName,
        userAvatar,
        action,
        subjectType,
        subjectId,
        description,
        createdAt,
      ];
}
