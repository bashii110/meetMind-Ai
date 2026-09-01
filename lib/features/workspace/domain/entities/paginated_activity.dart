import 'activity_log_entry.dart';

/// Matches the backend's `{ items, meta: { current_page, last_page, total } }`
/// envelope used across every paginated list endpoint in this app — see
/// GET /workspaces/{id}/activity.
class PaginatedActivity {
  const PaginatedActivity({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<ActivityLogEntry> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
