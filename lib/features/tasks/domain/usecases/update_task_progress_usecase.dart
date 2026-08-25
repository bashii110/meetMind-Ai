import '../entities/task.dart';
import '../repositories/task_repository.dart';

class UpdateTaskProgressUseCase {
  const UpdateTaskProgressUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskEntity> call(String id, int progress) => _repository.updateProgress(id, progress);
}
