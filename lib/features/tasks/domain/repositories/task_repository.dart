import 'dart:io';

import '../entities/paginated_tasks.dart';
import '../entities/task.dart';
import '../entities/task_filters.dart';

/// Implemented by data/repositories/task_repository_impl.dart. Use cases and
/// the presentation layer depend on this abstraction, never the impl
/// directly (ARCHITECTURE.md 2.1).
abstract interface class TaskRepository {
  Future<PaginatedTasks> list({TaskFilters filters = TaskFilters.empty, int page = 1});

  Future<TaskEntity> getById(String id);

  Future<TaskEntity> create({
    required String title,
    String? meetingId,
    String? description,
    String priority = 'medium',
    String status = 'pending',
    DateTime? deadline,
    String? assignedUserId,
  });

  /// Only the fields UpdateTaskRequest accepts on the backend — status,
  /// progress, and assignee are changed through their own endpoints below.
  Future<TaskEntity> update(
    String id, {
    String? title,
    String? description,
    String? priority,
    DateTime? deadline,
    String? meetingId,
  });

  Future<void> delete(String id);

  Future<TaskEntity> changeStatus(String id, String status);

  Future<TaskEntity> updateProgress(String id, int progress);

  /// Pass `null` to unassign.
  Future<TaskEntity> assign(String id, String? assignedUserId);

  Future<TaskComment> addComment(String id, String comment);

  Future<void> deleteComment(String taskId, String commentId);

  Future<TaskAttachment> addAttachment(String id, File file);

  Future<void> deleteAttachment(String taskId, String attachmentId);
}
