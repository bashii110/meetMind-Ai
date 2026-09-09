import '../entities/analytics_summary.dart';
import '../repositories/analytics_repository.dart';

class GetWorkspaceAnalyticsUseCase {
  const GetWorkspaceAnalyticsUseCase(this._repository);

  final AnalyticsRepository _repository;

  Future<AnalyticsSummary> call(String workspaceId) => _repository.getWorkspaceAnalytics(workspaceId);
}
