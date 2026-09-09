import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_user.dart';
import 'admin_providers.dart';

class AdminUsersState {
  const AdminUsersState({
    required this.items,
    required this.search,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<AdminUser> items;
  final String search;
  final bool hasMore;
  final bool isLoadingMore;

  AdminUsersState copyWith({
    List<AdminUser>? items,
    String? search,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return AdminUsersState(
      items: items ?? this.items,
      search: search ?? this.search,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// SRD FR-16.1: "Admins shall manage (view/disable) user accounts."
/// Mirrors `TasksListController`'s pagination + filter pattern.
class AdminUsersController extends AutoDisposeAsyncNotifier<AdminUsersState> {
  int _page = 1;

  @override
  Future<AdminUsersState> build() => _fetch('', page: 1);

  Future<AdminUsersState> _fetch(String search, {required int page}) async {
    final result = await ref.read(listAdminUsersUseCaseProvider)(search: search, page: page);
    _page = result.currentPage;
    return AdminUsersState(items: result.items, search: search, hasMore: result.hasMore);
  }

  Future<void> applySearch(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(query, page: 1));
  }

  Future<void> refresh() async {
    final search = state.valueOrNull?.search ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(search, page: 1));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final result = await ref.read(listAdminUsersUseCaseProvider)(search: current.search, page: _page + 1);
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

  /// Optimistically patches the toggled user in place rather than
  /// re-fetching the whole page — keeps the list scroll position stable.
  Future<void> toggleDisabled(AdminUser user) async {
    final updated = await ref.read(setUserDisabledUseCaseProvider)(user.id, !user.isDisabled);
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      items: [for (final u in current.items) if (u.id == updated.id) updated else u],
    ));
  }
}

final adminUsersControllerProvider =
    AsyncNotifierProvider.autoDispose<AdminUsersController, AdminUsersState>(AdminUsersController.new);
