import '../entities/task.dart';
import '../repositories/task_repository.dart';

class AddTaskCommentUseCase {
  const AddTaskCommentUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskComment> call(String taskId, String comment) => _repository.addComment(taskId, comment);
}
