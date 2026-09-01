import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/search_results.dart';
import 'search_providers.dart';

enum SearchFilter { all, meetings, tasks, users }

class SearchState {
  const SearchState({
    required this.query,
    required this.results,
    this.recentSearches = const [],
    this.filter = SearchFilter.all,
  });

  final String query;
  final AsyncValue<SearchResults> results;
  final List<String> recentSearches;
  final SearchFilter filter;

  SearchState copyWith({
    String? query,
    AsyncValue<SearchResults>? results,
    List<String>? recentSearches,
    SearchFilter? filter,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      filter: filter ?? this.filter,
    );
  }
}

/// Debounced global search — SRD FR-12.1. autoDispose: only matters while
/// SearchScreen is open. Recent searches are kept in memory only for this
/// session (not persisted) — see PHASE8_README.md for why.
class SearchController extends AutoDisposeNotifier<SearchState> {
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 400);

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return SearchState(query: '', results: AsyncData(SearchResults.empty('')));
  }

  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(results: AsyncData(SearchResults.empty('')));
      return;
    }

    _debounce = Timer(_debounceDuration, () => _runSearch(query.trim()));
  }

  Future<void> _runSearch(String query) async {
    state = state.copyWith(results: const AsyncLoading());
    final result = await AsyncValue.guard(() => ref.read(searchUseCaseProvider)(query));
    state = state.copyWith(results: result);
    if (result.hasValue) _pushRecent(query);
  }

  void setFilter(SearchFilter filter) => state = state.copyWith(filter: filter);

  /// Re-runs a search immediately for a tapped recent-search entry — no
  /// debounce, since this isn't a keystroke.
  void selectRecent(String query) {
    _debounce?.cancel();
    state = state.copyWith(query: query);
    _runSearch(query);
  }

  void clear() {
    _debounce?.cancel();
    state = state.copyWith(query: '', results: AsyncData(SearchResults.empty('')));
  }

  void _pushRecent(String query) {
    final updated = [query, ...state.recentSearches.where((q) => q != query)].take(8).toList();
    state = state.copyWith(recentSearches: updated);
  }
}

final searchControllerProvider = AutoDisposeNotifierProvider<SearchController, SearchState>(SearchController.new);
