import '../entities/task.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  const CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskEntity> call({
    required String title,
    String? meetingId,
    String? description,
    String priority = 'medium',
    String status = 'pending',
    DateTime? deadline,
    String? assignedUserId,
  }) {
    return _repository.create(
      title: title,
      meetingId: meetingId,
      description: description,
      priority: priority,
      status: status,
      deadline: deadline,
      assignedUserId: assignedUserId,
    );
  }
}
