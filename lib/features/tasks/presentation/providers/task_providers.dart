import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/task_remote_data_source.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/add_task_attachment_usecase.dart';
import '../../domain/usecases/add_task_comment_usecase.dart';
import '../../domain/usecases/assign_task_usecase.dart';
import '../../domain/usecases/change_task_status_usecase.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/delete_task_attachment_usecase.dart';
import '../../domain/usecases/delete_task_comment_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_task_usecase.dart';
import '../../domain/usecases/list_tasks_usecase.dart';
import '../../domain/usecases/update_task_progress_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';

final taskRemoteDataSourceProvider = Provider(
  (ref) => TaskRemoteDataSource(ref.watch(dioProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(ref.watch(taskRemoteDataSourceProvider)),
);

final listTasksUseCaseProvider = Provider((ref) => ListTasksUseCase(ref.watch(taskRepositoryProvider)));
final getTaskUseCaseProvider = Provider((ref) => GetTaskUseCase(ref.watch(taskRepositoryProvider)));
final createTaskUseCaseProvider = Provider((ref) => CreateTaskUseCase(ref.watch(taskRepositoryProvider)));
final updateTaskUseCaseProvider = Provider((ref) => UpdateTaskUseCase(ref.watch(taskRepositoryProvider)));
final deleteTaskUseCaseProvider = Provider((ref) => DeleteTaskUseCase(ref.watch(taskRepositoryProvider)));
final changeTaskStatusUseCaseProvider =
    Provider((ref) => ChangeTaskStatusUseCase(ref.watch(taskRepositoryProvider)));
final updateTaskProgressUseCaseProvider =
    Provider((ref) => UpdateTaskProgressUseCase(ref.watch(taskRepositoryProvider)));
final assignTaskUseCaseProvider = Provider((ref) => AssignTaskUseCase(ref.watch(taskRepositoryProvider)));
final addTaskCommentUseCaseProvider =
    Provider((ref) => AddTaskCommentUseCase(ref.watch(taskRepositoryProvider)));
final deleteTaskCommentUseCaseProvider =
    Provider((ref) => DeleteTaskCommentUseCase(ref.watch(taskRepositoryProvider)));
final addTaskAttachmentUseCaseProvider =
    Provider((ref) => AddTaskAttachmentUseCase(ref.watch(taskRepositoryProvider)));
final deleteTaskAttachmentUseCaseProvider =
    Provider((ref) => DeleteTaskAttachmentUseCase(ref.watch(taskRepositoryProvider)));
