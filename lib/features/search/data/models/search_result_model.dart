import '../../domain/entities/search_result.dart';

class SearchResultModel extends SearchResult {
  const SearchResultModel({
    required super.type,
    required super.id,
    required super.title,
    super.subtitle,
    super.matchedIn,
    super.date,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json, SearchResultType type) {
    return SearchResultModel(
      type: type,
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      matchedIn: json['matched_in'] as String?,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
    );
  }
}
