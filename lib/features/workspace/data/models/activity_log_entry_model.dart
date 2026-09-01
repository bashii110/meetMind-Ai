import '../../domain/entities/activity_log_entry.dart';

class ActivityLogEntryModel extends ActivityLogEntry {
  const ActivityLogEntryModel({
    required super.id,
    required super.workspaceId,
    required super.userId,
    required super.userName,
    required super.action,
    required super.createdAt,
    super.userAvatar,
    super.subjectType,
    super.subjectId,
    super.description,
  });

  factory ActivityLogEntryModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    return ActivityLogEntryModel(
      id: json['id'].toString(),
      workspaceId: json['workspace_id'].toString(),
      userId: (user?['id'] ?? json['user_id'] ?? '').toString(),
      userName: user?['name'] as String? ?? 'Someone',
      userAvatar: user?['avatar'] as String?,
      action: json['action'] as String? ?? '',
      subjectType: json['subject_type'] as String?,
      subjectId: json['subject_id']?.toString(),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
