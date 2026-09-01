import 'package:dio/dio.dart';

import '../models/search_results_model.dart';

/// Talks to GET /search — see ARCHITECTURE.md section 5's documented
/// `GET /api/v1/search?q=...` endpoint.
class SearchRemoteDataSource {
  const SearchRemoteDataSource(this._dio);

  final Dio _dio;

  Future<SearchResultsModel> search(String query) async {
    final response = await _dio.get('/search', queryParameters: {'q': query});
    return SearchResultsModel.fromJson(query, response.data['data'] as Map<String, dynamic>);
  }
}
