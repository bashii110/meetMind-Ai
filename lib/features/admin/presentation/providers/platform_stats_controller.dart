import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/platform_stats.dart';
import 'admin_providers.dart';

/// SRD FR-16.2. autoDispose — only fetched while the Admin screen's
/// Overview tab is mounted.
class PlatformStatsController extends AutoDisposeAsyncNotifier<PlatformStats> {
  @override
  Future<PlatformStats> build() => ref.read(getPlatformStatsUseCaseProvider)();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(getPlatformStatsUseCaseProvider)());
  }
}

final platformStatsControllerProvider =
    AsyncNotifierProvider.autoDispose<PlatformStatsController, PlatformStats>(PlatformStatsController.new);
