import '../entities/task.dart';
import '../repositories/task_repository.dart';

class ChangeTaskStatusUseCase {
  const ChangeTaskStatusUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskEntity> call(String id, String status) => _repository.changeStatus(id, status);
}
