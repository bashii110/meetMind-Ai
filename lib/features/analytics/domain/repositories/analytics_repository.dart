import '../entities/analytics_summary.dart';

/// Implemented by data/repositories/analytics_repository_impl.dart. Use
/// cases and the presentation layer depend on this abstraction, never the
/// impl directly (ARCHITECTURE.md 2.1).
abstract interface class AnalyticsRepository {
  Future<AnalyticsSummary> getWorkspaceAnalytics(String workspaceId);
}
