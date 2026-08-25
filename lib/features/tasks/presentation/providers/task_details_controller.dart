import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import 'task_providers.dart';
import 'tasks_list_controller.dart';

class TaskDetailsController extends AutoDisposeFamilyAsyncNotifier<TaskEntity, String> {
  @override
  Future<TaskEntity> build(String arg) {
    return ref.read(getTaskUseCaseProvider)(arg);
  }

  Future<void> changeStatus(String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(changeTaskStatusUseCaseProvider)(arg, status));
    _refreshList();
  }

  Future<void> updateProgress(int progress) async {
    // No AsyncLoading here — the caller (TaskDetailsScreen) keeps the
    // slider showing the dragged value locally while this is in flight, so
    // swapping to a full loading state would just cause a visible flicker.
    state = await AsyncValue.guard(() => ref.read(updateTaskProgressUseCaseProvider)(arg, progress));
    _refreshList();
  }

  Future<void> assign(String? userId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(assignTaskUseCaseProvider)(arg, userId));
    _refreshList();
  }

  Future<void> updateProfile({
    String? title,
    String? description,
    String? priority,
    DateTime? deadline,
    String? meetingId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(updateTaskUseCaseProvider)(
          arg,
          title: title,
          description: description,
          priority: priority,
          deadline: deadline,
          meetingId: meetingId,
        ));

    if (state.hasError) throw state.error!;
    _refreshList();
  }

  Future<void> addComment(String comment) async {
    await ref.read(addTaskCommentUseCaseProvider)(arg, comment);
    await _reload();
  }

  Future<void> deleteComment(String commentId) async {
    await ref.read(deleteTaskCommentUseCaseProvider)(arg, commentId);
    await _reload();
  }

  Future<void> addAttachment(File file) async {
    await ref.read(addTaskAttachmentUseCaseProvider)(arg, file);
    await _reload();
  }

  Future<void> deleteAttachment(String attachmentId) async {
    await ref.read(deleteTaskAttachmentUseCaseProvider)(arg, attachmentId);
    await _reload();
  }

  Future<void> delete() async {
    await ref.read(deleteTaskUseCaseProvider)(arg);
    _refreshList();
  }

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(getTaskUseCaseProvider)(arg));
  }

  void _refreshList() {
    ref.read(tasksListControllerProvider.notifier).refresh();
  }
}

final taskDetailsControllerProvider =
    AsyncNotifierProvider.autoDispose.family<TaskDetailsController, TaskEntity, String>(
  TaskDetailsController.new,
);
