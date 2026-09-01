import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/activity_log_entry.dart';
import 'workspace_providers.dart';

class WorkspaceActivityState {
  const WorkspaceActivityState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<ActivityLogEntry> items;
  final bool hasMore;
  final bool isLoadingMore;

  WorkspaceActivityState copyWith({
    List<ActivityLogEntry>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return WorkspaceActivityState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Paginated activity timeline for a workspace — SRD FR-10.4. autoDispose
/// + family by workspaceId: only matters while the Activity tab is open.
class WorkspaceActivityController extends AutoDisposeFamilyAsyncNotifier<WorkspaceActivityState, String> {
  int _page = 1;

  @override
  Future<WorkspaceActivityState> build(String arg) => _fetch(page: 1);

  Future<WorkspaceActivityState> _fetch({required int page}) async {
    final result = await ref.read(listWorkspaceActivityUseCaseProvider)(arg, page: page);
    _page = result.currentPage;
    return WorkspaceActivityState(items: result.items, hasMore: result.hasMore);
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
      final result = await ref.read(listWorkspaceActivityUseCaseProvider)(arg, page: _page + 1);
      _page = result.currentPage;
      state = AsyncData(current.copyWith(
        items: [...current.items, ...result.items],
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (_) {
      // Leave the existing list showing; just stop the load-more spinner —
      // same convention as TasksListController.loadMore.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final workspaceActivityControllerProvider = AsyncNotifierProvider.autoDispose
    .family<WorkspaceActivityController, WorkspaceActivityState, String>(WorkspaceActivityController.new);
