import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task_filters.dart';
import 'task_providers.dart';

class TaskStats {
  const TaskStats({required this.pending, required this.completed});

  final int pending;
  final int completed;
}

/// Lightweight counts for the dashboard's "Pending Tasks / Completed Tasks"
/// stat row (DESIGN.md 3.3) — two small paginated queries, read purely for
/// their `meta.total`, rather than pulling every task into memory.
final taskStatsProvider = FutureProvider.autoDispose<TaskStats>((ref) async {
  final list = ref.watch(listTasksUseCaseProvider);
  final pending = await list(filters: const TaskFilters(status: 'pending'), page: 1);
  final completed = await list(filters: const TaskFilters(status: 'completed'), page: 1);
  return TaskStats(pending: pending.total, completed: completed.total);
});
