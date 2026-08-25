import 'dart:io';

import '../../domain/entities/paginated_tasks.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_filters.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._remote);

  final TaskRemoteDataSource _remote;

  @override
  Future<PaginatedTasks> list({TaskFilters filters = TaskFilters.empty, int page = 1}) {
    return _remote.list(filters.toQueryParameters(), page);
  }

  @override
  Future<TaskEntity> getById(String id) => _remote.getById(id);

  @override
  Future<TaskEntity> create({
    required String title,
    String? meetingId,
    String? description,
    String priority = 'medium',
    String status = 'pending',
    DateTime? deadline,
    String? assignedUserId,
  }) {
    return _remote.create({
      if (meetingId != null) 'meeting_id': int.tryParse(meetingId) ?? meetingId,
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'priority': priority,
      'status': status,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
      if (assignedUserId != null) 'assigned_user_id': int.tryParse(assignedUserId) ?? assignedUserId,
    });
  }

  @override
  Future<TaskEntity> update(
    String id, {
    String? title,
    String? description,
    String? priority,
    DateTime? deadline,
    String? meetingId,
  }) {
    return _remote.update(id, {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
      if (meetingId != null) 'meeting_id': int.tryParse(meetingId) ?? meetingId,
    });
  }

  @override
  Future<void> delete(String id) => _remote.delete(id);

  @override
  Future<TaskEntity> changeStatus(String id, String status) => _remote.changeStatus(id, status);

  @override
  Future<TaskEntity> updateProgress(String id, int progress) => _remote.updateProgress(id, progress);

  @override
  Future<TaskEntity> assign(String id, String? assignedUserId) => _remote.assign(id, assignedUserId);

  @override
  Future<TaskComment> addComment(String id, String comment) => _remote.addComment(id, comment);

  @override
  Future<void> deleteComment(String taskId, String commentId) => _remote.deleteComment(taskId, commentId);

  @override
  Future<TaskAttachment> addAttachment(String id, File file) => _remote.addAttachment(id, file);

  @override
  Future<void> deleteAttachment(String taskId, String attachmentId) {
    return _remote.deleteAttachment(taskId, attachmentId);
  }
}
