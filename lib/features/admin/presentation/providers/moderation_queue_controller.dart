import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/moderation_item.dart';
import 'admin_providers.dart';

class ModerationQueueState {
  const ModerationQueueState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<ModerationItem> items;
  final bool hasMore;
  final bool isLoadingMore;

  ModerationQueueState copyWith({
    List<ModerationItem>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ModerationQueueState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// SRD FR-16.3: "Admins shall moderate reported content."
class ModerationQueueController extends AutoDisposeAsyncNotifier<ModerationQueueState> {
  int _page = 1;

  @override
  Future<ModerationQueueState> build() => _fetch(page: 1);

  Future<ModerationQueueState> _fetch({required int page}) async {
    final result = await ref.read(listModerationQueueUseCaseProvider)(page: page);
    _page = result.currentPage;
    return ModerationQueueState(items: result.items, hasMore: result.hasMore);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final result = await ref.read(listModerationQueueUseCaseProvider)(page: _page + 1);
      _page = result.currentPage;
      state = AsyncData(current.copyWith(
        items: [...current.items, ...result.items],
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// [remove] true deletes the reported content; false dismisses the
  /// report. Either way the item leaves the pending queue, so it's
  /// removed from local state rather than re-fetched.
  Future<void> resolve(String itemId, {required bool remove}) async {
    await ref.read(resolveModerationItemUseCaseProvider)(itemId, remove: remove);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(items: current.items.where((i) => i.id != itemId).toList()));
  }
}

final moderationQueueControllerProvider =
    AsyncNotifierProvider.autoDispose<ModerationQueueController, ModerationQueueState>(
  ModerationQueueController.new,
);
