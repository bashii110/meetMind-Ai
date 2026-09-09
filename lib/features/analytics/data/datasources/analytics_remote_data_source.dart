import 'package:dio/dio.dart';

import '../models/analytics_summary_model.dart';

/// Talks to GET /workspaces/{id}/analytics — see ARCHITECTURE.md section
/// 5's documented endpoint example.
class AnalyticsRemoteDataSource {
  const AnalyticsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AnalyticsSummaryModel> getWorkspaceAnalytics(String workspaceId) async {
    final response = await _dio.get('/workspaces/$workspaceId/analytics');
    return AnalyticsSummaryModel.fromJson(workspaceId, response.data['data'] as Map<String, dynamic>);
  }
}
