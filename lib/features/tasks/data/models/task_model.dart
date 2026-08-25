import '../../../auth/data/models/app_user_model.dart';
import '../../domain/entities/task.dart';

class TaskCommentModel extends TaskComment {
  const TaskCommentModel({
    required super.id,
    required super.comment,
    required super.user,
    required super.createdAt,
  });

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) {
    return TaskCommentModel(
      id: json['id'].toString(),
      comment: json['comment'] as String? ?? '',
      user: AppUserModel.fromJson((json['user'] as Map?)?.cast<String, dynamic>() ?? const {}),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TaskAttachmentModel extends TaskAttachment {
  const TaskAttachmentModel({
    required super.id,
    required super.originalFilename,
    required super.uploadedBy,
    required super.createdAt,
    super.size,
  });

  factory TaskAttachmentModel.fromJson(Map<String, dynamic> json) {
    return TaskAttachmentModel(
      id: json['id'].toString(),
      originalFilename: json['original_filename'] as String? ?? 'file',
      size: json['size'] as int?,
      uploadedBy: AppUserModel.fromJson((json['uploaded_by'] as Map?)?.cast<String, dynamic>() ?? const {}),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Maps backend/app/Http/Resources/TaskResource.php. `creator` is always
/// eager-loaded by the backend so it's parsed unconditionally; `assignee`
/// is nullable JSON (no assigned_user_id) so it's parsed only when present.
class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.workspaceId,
    required super.title,
    required super.priority,
    required super.status,
    required super.progress,
    required super.isOverdue,
    required super.createdAt,
    super.meetingId,
    super.meetingTitle,
    super.description,
    super.deadline,
    super.creator,
    super.assignee,
    super.commentCount,
    super.comments,
    super.attachments,
    super.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    final assignee = json['assignee'] as Map<String, dynamic>?;
    final comments = (json['comments'] as List?) ?? const [];
    final attachments = (json['attachments'] as List?) ?? const [];

    return TaskModel(
      id: json['id'].toString(),
      workspaceId: json['workspace_id'].toString(),
      meetingId: json['meeting_id']?.toString(),
      meetingTitle: json['meeting_title'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      progress: json['progress'] as int? ?? 0,
      isOverdue: json['is_overdue'] as bool? ?? false,
      creator: creator != null && creator.isNotEmpty ? AppUserModel.fromJson(creator) : null,
      assignee: assignee != null && assignee.isNotEmpty ? AppUserModel.fromJson(assignee) : null,
      // comment_count is only present when the backend used withCount (the
      // list endpoint); the details endpoint loads the comments themselves
      // instead, so fall back to their length rather than showing 0.
      commentCount: json['comment_count'] as int? ?? comments.length,
      comments: comments.map((c) => TaskCommentModel.fromJson(c as Map<String, dynamic>)).toList(),
      attachments: attachments.map((a) => TaskAttachmentModel.fromJson(a as Map<String, dynamic>)).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }
}
