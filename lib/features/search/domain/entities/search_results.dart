import 'search_result.dart';

/// Matches the backend's `{ meetings, tasks, users }` categorized envelope
/// for GET /search — see ARCHITECTURE.md's documented
/// `GET /api/v1/search?q=...` endpoint. Kept as three separate lists
/// (rather than one flat list with a type filter) since the search screen
/// renders them as distinct sections.
class SearchResults {
  const SearchResults({
    required this.query,
    required this.meetings,
    required this.tasks,
    required this.users,
  });

  final String query;
  final List<SearchResult> meetings;
  final List<SearchResult> tasks;
  final List<SearchResult> users;

  factory SearchResults.empty(String query) =>
      SearchResults(query: query, meetings: const [], tasks: const [], users: const []);

  int get totalCount => meetings.length + tasks.length + users.length;

  bool get isEmpty => totalCount == 0;
}
