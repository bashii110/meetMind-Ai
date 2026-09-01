import '../entities/search_results.dart';
import '../repositories/search_repository.dart';

class SearchUseCase {
  const SearchUseCase(this._repository);

  final SearchRepository _repository;

  /// SRD FR-12.1.
  Future<SearchResults> call(String query) => _repository.search(query);
}
