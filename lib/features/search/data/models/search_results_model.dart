import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_results.dart';
import 'search_result_model.dart';

class SearchResultsModel extends SearchResults {
  const SearchResultsModel({
    required super.query,
    required super.meetings,
    required super.tasks,
    required super.users,
  });

  factory SearchResultsModel.fromJson(String query, Map<String, dynamic> json) {
    List<SearchResultModel> parse(String key, SearchResultType type) {
      final list = (json[key] as List?) ?? const [];
      return list.map((e) => SearchResultModel.fromJson(e as Map<String, dynamic>, type)).toList();
    }

    return SearchResultsModel(
      query: query,
      meetings: parse('meetings', SearchResultType.meeting),
      tasks: parse('tasks', SearchResultType.task),
      users: parse('users', SearchResultType.user),
    );
  }
}
