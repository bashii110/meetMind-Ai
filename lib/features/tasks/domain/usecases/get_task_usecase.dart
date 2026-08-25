import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTaskUseCase {
  const GetTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskEntity> call(String id) => _repository.getById(id);
}
