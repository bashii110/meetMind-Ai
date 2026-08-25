import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/task_filters.dart';
import 'task_providers.dart';

class TasksListState {
  const TasksListState({
    required this.items,
    required this.filters,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<TaskEntity> items;
  final TaskFilters filters;
  final bool hasMore;
  final bool isLoadingMore;

  TasksListState copyWith({
    List<TaskEntity>? items,
    TaskFilters? filters,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TasksListState(
      items: items ?? this.items,
      filters: filters ?? this.filters,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TasksListController extends AsyncNotifier<TasksListState> {
  int _page = 1;

  @override
  Future<TasksListState> build() => _fetch(TaskFilters.empty, page: 1);

  Future<TasksListState> _fetch(TaskFilters filters, {required int page}) async {
    final result = await ref.read(listTasksUseCaseProvider)(filters: filters, page: page);
    _page = result.currentPage;
    return TasksListState(items: result.items, filters: filters, hasMore: result.hasMore);
  }

  Future<void> refresh() async {
    final filters = state.valueOrNull?.filters ?? TaskFilters.empty;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(filters, page: 1));
  }

  Future<void> applyFilters(TaskFilters filters) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(filters, page: 1));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final result = await ref.read(listTasksUseCaseProvider)(
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

final tasksListControllerProvider =
    AsyncNotifierProvider<TasksListController, TasksListState>(TasksListController.new);
