import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/analytics_summary.dart';
import 'analytics_providers.dart';

/// SRD FR-13.1. autoDispose + family by workspaceId: only fetched while
/// AnalyticsScreen has that workspace selected.
class AnalyticsController extends AutoDisposeFamilyAsyncNotifier<AnalyticsSummary, String> {
  @override
  Future<AnalyticsSummary> build(String arg) => ref.read(getWorkspaceAnalyticsUseCaseProvider)(arg);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(getWorkspaceAnalyticsUseCaseProvider)(arg));
  }
}

final analyticsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AnalyticsController, AnalyticsSummary, String>(AnalyticsController.new);
