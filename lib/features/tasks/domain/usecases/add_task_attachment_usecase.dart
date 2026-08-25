import 'dart:io';

import '../entities/task.dart';
import '../repositories/task_repository.dart';

class AddTaskAttachmentUseCase {
  const AddTaskAttachmentUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskAttachment> call(String taskId, File file) => _repository.addAttachment(taskId, file);
}
