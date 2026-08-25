import '../repositories/task_repository.dart';

class DeleteTaskCommentUseCase {
  const DeleteTaskCommentUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call(String taskId, String commentId) => _repository.deleteComment(taskId, commentId);
}
