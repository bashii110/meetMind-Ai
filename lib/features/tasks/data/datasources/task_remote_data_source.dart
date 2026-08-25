import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../models/paginated_tasks_model.dart';
import '../models/task_model.dart';

class TaskRemoteDataSource {
  const TaskRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PaginatedTasksModel> list(Map<String, dynamic> queryParameters, int page) async {
    final response = await _dio.get('/tasks', queryParameters: {
      ...queryParameters,
      'page': page,
    });
    return PaginatedTasksModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TaskModel> getById(String id) async {
    final response = await _dio.get('/tasks/$id');
    return TaskModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TaskModel> create(Map<String, dynamic> body) async {
    final response = await _dio.post('/tasks', data: body);
    return TaskModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TaskModel> update(String id, Map<String, dynamic> body) async {
    final response = await _dio.put('/tasks/$id', data: body);
    return TaskModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/tasks/$id');

  Future<TaskModel> changeStatus(String id, String status) async {
    final response = await _dio.patch('/tasks/$id/status', data: {'status': status});
    return TaskModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TaskModel> updateProgress(String id, int progress) async {
    final response = await _dio.patch('/tasks/$id/progress', data: {'progress': progress});
    return TaskModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TaskModel> assign(String id, String? assignedUserId) async {
    final response = await _dio.patch('/tasks/$id/assign', data: {
      'assigned_user_id': assignedUserId != null ? (int.tryParse(assignedUserId) ?? assignedUserId) : null,
    });
    return TaskModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TaskCommentModel> addComment(String id, String comment) async {
    final response = await _dio.post('/tasks/$id/comments', data: {'comment': comment});
    return TaskCommentModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteComment(String taskId, String commentId) {
    return _dio.delete('/tasks/$taskId/comments/$commentId');
  }

  Future<TaskAttachmentModel> addAttachment(String id, File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: p.basename(file.path)),
    });
    final response = await _dio.post('/tasks/$id/attachments', data: form);
    return TaskAttachmentModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAttachment(String taskId, String attachmentId) {
    return _dio.delete('/tasks/$taskId/attachments/$attachmentId');
  }
}
