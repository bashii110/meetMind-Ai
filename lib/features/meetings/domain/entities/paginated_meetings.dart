import 'meeting.dart';

/// Matches the backend's `{ items, meta: { current_page, last_page, total } }`
/// envelope for GET /meetings — see MeetingController::index.
class PaginatedMeetings {
  const PaginatedMeetings({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<Meeting> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
