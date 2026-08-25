import '../entities/paginated_tasks.dart';
import '../entities/task_filters.dart';
import '../repositories/task_repository.dart';

class ListTasksUseCase {
  const ListTasksUseCase(this._repository);

  final TaskRepository _repository;

  Future<PaginatedTasks> call({TaskFilters filters = TaskFilters.empty, int page = 1}) {
    return _repository.list(filters: filters, page: page);
  }
}
