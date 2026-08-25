import '../repositories/task_repository.dart';

class DeleteTaskAttachmentUseCase {
  const DeleteTaskAttachmentUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call(String taskId, String attachmentId) => _repository.deleteAttachment(taskId, attachmentId);
}
