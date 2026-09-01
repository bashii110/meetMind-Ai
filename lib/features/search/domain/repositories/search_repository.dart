import '../entities/search_results.dart';

/// Implemented by data/repositories/search_repository_impl.dart. Use
/// cases and the presentation layer depend on this abstraction, never the
/// impl directly (ARCHITECTURE.md 2.1).
abstract interface class SearchRepository {
  Future<SearchResults> search(String query);
}
