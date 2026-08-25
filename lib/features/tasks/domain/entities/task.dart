import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/app_user.dart';

/// SRD FR-7.x. A task's `creator`/`assignee` mirror the backend's
/// UserResource shape, so this reuses [AppUser] rather than duplicating an
/// entity — the same convention `profile` uses for the same reason (see
/// frontend/README.md's Architecture section).
class TaskComment extends Equatable {
  const TaskComment({
    required this.id,
    required this.comment,
    required this.user,
    required this.createdAt,
  });

  final String id;
  final String comment;
  final AppUser user;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, comment, user, createdAt];
}

class TaskAttachment extends Equatable {
  const TaskAttachment({
    required this.id,
    required this.originalFilename,
    required this.uploadedBy,
    required this.createdAt,
    this.size,
  });

  final String id;
  final String originalFilename;
  final int? size;
  final AppUser uploadedBy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, originalFilename, size, uploadedBy, createdAt];
}

/// Mirrors backend/app/Http/Resources/TaskResource.php. `comments` and
/// `attachments` are only populated when the backend eager-loads those
/// relations (task details / show), so default to empty lists on the
/// lighter list endpoint rather than treating a missing key as an error.
class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.priority,
    required this.status,
    required this.progress,
    required this.isOverdue,
    required this.createdAt,
    this.meetingId,
    this.meetingTitle,
    this.description,
    this.deadline,
    this.creator,
    this.assignee,
    this.commentCount = 0,
    this.comments = const [],
    this.attachments = const [],
    this.updatedAt,
  });

  final String id;
  final String workspaceId;
  final String? meetingId;
  final String? meetingTitle;
  final String title;
  final String? description;
  final String priority; // low | medium | high
  final String status; // pending | in_progress | completed | cancelled
  final DateTime? deadline;
  final int progress; // 0-100
  final bool isOverdue;
  final AppUser? creator;
  final AppUser? assignee;
  final int commentCount;
  final List<TaskComment> comments;
  final List<TaskAttachment> attachments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        meetingId,
        meetingTitle,
        title,
        description,
        priority,
        status,
        deadline,
        progress,
        isOverdue,
        creator,
        assignee,
        commentCount,
        comments,
        attachments,
        createdAt,
        updatedAt,
      ];
}
