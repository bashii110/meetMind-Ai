import 'dart:io';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/outbox_entry.dart';
import '../../../../core/sync/outbox_local_data_source.dart';
import '../../domain/entities/paginated_tasks.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_filters.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

const _uuid = Uuid();

/// Phase 10: cache-first reads, outbox-queued writes when offline — same
/// pattern as MeetingRepositoryImpl, plus a [OutboxEntry.baseUpdatedAt]
/// snapshot on every queued update so OutboxSyncManager can tell whether
/// the task changed on the server in the meantime (tasks get a
/// manual-merge conflict prompt instead of meetings' last-write-wins).
///
/// Progress, assignment, comments, and attachments stay online-only for
/// this phase — see PHASE10_README.md's known simplifications.
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(
    this._remote, {
    TaskLocalDataSource? local,
    OutboxLocalDataSource? outbox,
    bool Function()? isOnline,
  })  : _local = local ?? TaskLocalDataSource(),
        _outbox = outbox ?? OutboxLocalDataSource(),
        _isOnline = isOnline ?? (() => true);

  final TaskRemoteDataSource _remote;
  final TaskLocalDataSource _local;
  final OutboxLocalDataSource _outbox;
  final bool Function() _isOnline;

  bool _isConnectionError(Object e) => e is DioException && e.type == DioExceptionType.connectionError;

  @override
  Future<PaginatedTasks> list({TaskFilters filters = TaskFilters.empty, int page = 1}) async {
    try {
      final result = await _remote.list(filters.toQueryParameters(), page);
      if (page == 1) await _local.saveAll(result.items);
      return result;
    } catch (e) {
      if (!_isConnectionError(e) && _isOnline()) rethrow;
      final cached = _local.getAll();
      return PaginatedTasks(items: cached, currentPage: 1, lastPage: 1, total: cached.length);
    }
  }

  @override
  Future<TaskEntity> getById(String id) async {
    try {
      final task = await _remote.getById(id);
      await _local.save(task);
      return task;
    } catch (e) {
      final cached = _local.getById(id);
      if (cached != null && (_isConnectionError(e) || !_isOnline())) return cached;
      rethrow;
    }
  }

  @override
  Future<TaskEntity> create({
    required String title,
    String? meetingId,
    String? description,
    String priority = 'medium',
    String status = 'pending',
    DateTime? deadline,
    String? assignedUserId,
  }) async {
    final body = {
      if (meetingId != null) 'meeting_id': int.tryParse(meetingId) ?? meetingId,
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'priority': priority,
      'status': status,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
      if (assignedUserId != null) 'assigned_user_id': int.tryParse(assignedUserId) ?? assignedUserId,
    };

    if (_isOnline()) {
      try {
        final created = await _remote.create(body);
        await _local.save(created);
        return created;
      } catch (e) {
        if (!_isConnectionError(e)) rethrow;
      }
    }

    final localId = 'local_${_uuid.v4()}';
    final now = DateTime.now();
    final localTask = TaskModel(
      id: localId,
      workspaceId: '',
      meetingId: meetingId,
      title: title,
      description: description,
      priority: priority,
      status: status,
      deadline: deadline,
      progress: 0,
      isOverdue: false,
      createdAt: now,
      updatedAt: now,
    );
    await _local.save(localTask);
    await _outbox.add(OutboxEntry(
      id: _uuid.v4(),
      entityType: OutboxEntityType.task,
      operation: OutboxOperation.create,
      localId: localId,
      payload: body,
      createdAt: now,
    ));
    return localTask;
  }

  @override
  Future<TaskEntity> update(
    String id, {
    String? title,
    String? description,
    String? priority,
    DateTime? deadline,
    String? meetingId,
  }) async {
    final body = {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
      if (meetingId != null) 'meeting_id': int.tryParse(meetingId) ?? meetingId,
    };

    if (_isOnline()) {
      try {
        final updated = await _remote.update(id, body);
        await _local.save(updated);
        return updated;
      } catch (e) {
        if (!_isConnectionError(e)) rethrow;
      }
    }

    final cached = _local.getById(id);
    final patched = TaskModel(
      id: id,
      workspaceId: cached?.workspaceId ?? '',
      meetingId: meetingId ?? cached?.meetingId,
      meetingTitle: cached?.meetingTitle,
      title: title ?? cached?.title ?? '',
      description: description ?? cached?.description,
      priority: priority ?? cached?.priority ?? 'medium',
      status: cached?.status ?? 'pending',
      deadline: deadline ?? cached?.deadline,
      progress: cached?.progress ?? 0,
      isOverdue: cached?.isOverdue ?? false,
      creator: cached?.creator,
      assignee: cached?.assignee,
      commentCount: cached?.commentCount ?? 0,
      createdAt: cached?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _local.save(patched);
    await _outbox.add(OutboxEntry(
      id: _uuid.v4(),
      entityType: OutboxEntityType.task,
      operation: OutboxOperation.update,
      localId: id,
      payload: body,
      createdAt: DateTime.now(),
      // What updated_at looked like right before this edit —
      // OutboxSyncManager compares this to the server's copy at replay
      // time to tell whether someone else changed the task in between.
      baseUpdatedAt: cached?.updatedAt,
    ));
    return patched;
  }

  @override
  Future<void> delete(String id) async {
    if (_isOnline()) {
      try {
        await _remote.delete(id);
        await _local.delete(id);
        return;
      } catch (e) {
        if (!_isConnectionError(e)) rethrow;
      }
    }
    await _local.delete(id);
    await _outbox.add(OutboxEntry(
      id: _uuid.v4(),
      entityType: OutboxEntityType.task,
      operation: OutboxOperation.delete,
      localId: id,
      payload: const {},
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<TaskEntity> changeStatus(String id, String status) async {
    if (_isOnline()) {
      try {
        final updated = await _remote.changeStatus(id, status);
        await _local.save(updated);
        return updated;
      } catch (e) {
        if (!_isConnectionError(e)) rethrow;
      }
    }
    final cached = _local.getById(id);
    final base = cached ??
        TaskModel(
          id: id,
          workspaceId: '',
          title: '',
          priority: 'medium',
          status: status,
          progress: 0,
          isOverdue: false,
          createdAt: DateTime.now(),
        );
    final withStatus = TaskModel(
      id: base.id,
      workspaceId: base.workspaceId,
      meetingId: base.meetingId,
      meetingTitle: base.meetingTitle,
      title: base.title,
      description: base.description,
      priority: base.priority,
      status: status,
      deadline: base.deadline,
      progress: base.progress,
      isOverdue: base.isOverdue,
      creator: base.creator,
      assignee: base.assignee,
      commentCount: base.commentCount,
      createdAt: base.createdAt,
      updatedAt: DateTime.now(),
    );
    await _local.save(withStatus);
    await _outbox.add(OutboxEntry(
      id: _uuid.v4(),
      entityType: OutboxEntityType.task,
      operation: OutboxOperation.changeStatus,
      localId: id,
      payload: {'status': status},
      createdAt: DateTime.now(),
    ));
    return withStatus;
  }

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
