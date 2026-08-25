import '../entities/task.dart';
import '../repositories/task_repository.dart';

class AssignTaskUseCase {
  const AssignTaskUseCase(this._repository);

  final TaskRepository _repository;

  /// Pass `null` to unassign.
  Future<TaskEntity> call(String id, String? assignedUserId) => _repository.assign(id, assignedUserId);
}
