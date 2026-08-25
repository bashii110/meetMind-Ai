import '../entities/task.dart';
import '../repositories/task_repository.dart';

class UpdateTaskUseCase {
  const UpdateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskEntity> call(
    String id, {
    String? title,
    String? description,
    String? priority,
    DateTime? deadline,
    String? meetingId,
  }) {
    return _repository.update(
      id,
      title: title,
      description: description,
      priority: priority,
      deadline: deadline,
      meetingId: meetingId,
    );
  }
}
