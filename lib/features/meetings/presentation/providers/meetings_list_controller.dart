import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_filters.dart';
import 'meeting_providers.dart';

class MeetingsListState {
  const MeetingsListState({
    required this.items,
    required this.filters,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<Meeting> items;
  final MeetingFilters filters;
  final bool hasMore;
  final bool isLoadingMore;

  MeetingsListState copyWith({
    List<Meeting>? items,
    MeetingFilters? filters,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return MeetingsListState(
      items: items ?? this.items,
      filters: filters ?? this.filters,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class MeetingsListController extends AsyncNotifier<MeetingsListState> {
  int _page = 1;

  @override
  Future<MeetingsListState> build() => _fetch(MeetingFilters.empty, page: 1);

  Future<MeetingsListState> _fetch(MeetingFilters filters, {required int page}) async {
    final result = await ref.read(listMeetingsUseCaseProvider)(filters: filters, page: page);
    _page = result.currentPage;
    return MeetingsListState(items: result.items, filters: filters, hasMore: result.hasMore);
  }

  Future<void> refresh() async {
    final filters = state.valueOrNull?.filters ?? MeetingFilters.empty;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(filters, page: 1));
  }

  Future<void> applyFilters(MeetingFilters filters) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(filters, page: 1));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final result = await ref.read(listMeetingsUseCaseProvider)(
        filters: current.filters,
        page: _page + 1,
      );
      _page = result.currentPage;
      state = AsyncData(current.copyWith(
        items: [...current.items, ...result.items],
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (_) {
      // Leave the existing list showing; just stop the load-more spinner.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final meetingsListControllerProvider =
    AsyncNotifierProvider<MeetingsListController, MeetingsListState>(MeetingsListController.new);
