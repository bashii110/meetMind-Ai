import 'task.dart';

/// Matches the backend's `{ items, meta: { current_page, last_page, total } }`
/// envelope for GET /tasks — see TaskController::index.
class PaginatedTasks {
  const PaginatedTasks({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<TaskEntity> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
