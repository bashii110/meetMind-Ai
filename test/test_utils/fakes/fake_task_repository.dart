import 'dart:io';

import 'package:meetmind_ai/features/tasks/domain/entities/paginated_tasks.dart';
import 'package:meetmind_ai/features/tasks/domain/entities/task.dart';
import 'package:meetmind_ai/features/tasks/domain/entities/task_filters.dart';
import 'package:meetmind_ai/features/tasks/domain/repositories/task_repository.dart';

/// Hand-written fake (no mockito/mocktail dependency, matching this
/// project's no-codegen convention). Only `list()` has real paging
/// behavior — everything else is either a passthrough over [items] or an
/// [UnimplementedError], since controller tests only exercise the read
/// path.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({List<TaskEntity> items = const [], this.pageSize = 2, this.totalPages = 1})
      : items = List.of(items);

  List<TaskEntity> items;
  final int pageSize;
  final int totalPages;

  /// Set to make the next `list()` call throw instead of returning data.
  Object? listError;

  TaskFilters? lastFilters;
  int? lastPage;

  @override
  Future<PaginatedTasks> list({TaskFilters filters = TaskFilters.empty, int page = 1}) async {
    lastFilters = filters;
    lastPage = page;
    if (listError != null) throw listError!;

    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, items.length);
    final pageItems = start >= items.length ? const <TaskEntity>[] : items.sublist(start, end);

    return PaginatedTasks(items: pageItems, currentPage: page, lastPage: totalPages, total: items.length);
  }

  @override
  Future<TaskEntity> getById(String id) async => items.firstWhere((t) => t.id == id);

  @override
  Future<TaskEntity> create({
    required String title,
    String? meetingId,
    String? description,
    String priority = 'medium',
    String status = 'pending',
    DateTime? deadline,
    String? assignedUserId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<TaskEntity> update(
    String id, {
    String? title,
    String? description,
    String? priority,
    DateTime? deadline,
    String? meetingId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) async {}

  @override
  Future<TaskEntity> changeStatus(String id, String status) async => items.firstWhere((t) => t.id == id);

  @override
  Future<TaskEntity> updateProgress(String id, int progress) async => items.firstWhere((t) => t.id == id);

  @override
  Future<TaskEntity> assign(String id, String? assignedUserId) async => items.firstWhere((t) => t.id == id);

  @override
  Future<TaskComment> addComment(String id, String comment) async => throw UnimplementedError();

  @override
  Future<void> deleteComment(String taskId, String commentId) async {}

  @override
  Future<TaskAttachment> addAttachment(String id, File file) async => throw UnimplementedError();

  @override
  Future<void> deleteAttachment(String taskId, String attachmentId) async {}
}
