import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_filters.dart';
import '../providers/tasks_list_controller.dart';
import '../widgets/task_card.dart';

const _statusColumns = ['pending', 'in_progress', 'completed', 'cancelled'];
const _statusLabels = {
  'pending': 'Pending',
  'in_progress': 'In Progress',
  'completed': 'Completed',
  'cancelled': 'Cancelled',
};
const _priorityOptions = ['low', 'medium', 'high'];

/// DESIGN.md 3.7: Kanban columns on wide/tablet screens, a grouped list
/// with status chips on mobile. Both views share [tasksListControllerProvider]
/// — the Kanban board groups whatever page(s) are currently loaded into
/// columns client-side, rather than running four separate paginated
/// queries per status.
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters(
    TaskFilters current, {
    String? status,
    bool clearStatus = false,
    String? priority,
    bool clearPriority = false,
    bool? assignedToMe,
    String? search,
  }) {
    ref.read(tasksListControllerProvider.notifier).applyFilters(
          current.copyWith(
            status: status,
            clearStatus: clearStatus,
            priority: priority,
            clearPriority: clearPriority,
            assignedToMe: assignedToMe,
            search: search,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksListControllerProvider);
    final filters = state.valueOrNull?.filters ?? TaskFilters.empty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return Scaffold(
          appBar: AppBar(title: const Text('Tasks')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.taskNew),
            icon: const Icon(Icons.add),
            label: const Text('New task'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, Spacing.sm),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(hintText: 'Search tasks', prefixIcon: Icon(Icons.search)),
                  onSubmitted: (value) => _applyFilters(filters, search: value),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  children: [
                    FilterChip(
                      label: const Text('Assigned to me'),
                      selected: filters.assignedToMe,
                      onSelected: (selected) => _applyFilters(filters, assignedToMe: selected),
                    ),
                    const SizedBox(width: Spacing.sm),
                    for (final priority in _priorityOptions) ...[
                      FilterChip(
                        label: Text(priority[0].toUpperCase() + priority.substring(1)),
                        selected: filters.priority == priority,
                        onSelected: (selected) => _applyFilters(
                          filters,
                          priority: selected ? priority : null,
                          clearPriority: !selected,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                    ],
                    // Status is chosen via Kanban columns on wide screens,
                    // so these chips are only needed for the mobile list.
                    if (!isWide)
                      for (final status in _statusColumns) ...[
                        FilterChip(
                          label: Text(_statusLabels[status]!),
                          selected: filters.status == status,
                          onSelected: (selected) => _applyFilters(
                            filters,
                            status: selected ? status : null,
                            clearStatus: !selected,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Expanded(
                child: state.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(error is ApiFailure ? error.message : 'Could not load tasks.'),
                  ),
                  data: (list) {
                    if (list.items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.checklist_outlined,
                        title: 'No tasks yet',
                        message: 'Tap "New task" to create your first one.',
                      );
                    }

                    return isWide
                        ? _KanbanBoard(items: list.items, hasMore: list.hasMore, isLoadingMore: list.isLoadingMore)
                        : _GroupedList(items: list.items, hasMore: list.hasMore, isLoadingMore: list.isLoadingMore);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupedList extends ConsumerWidget {
  const _GroupedList({required this.items, required this.hasMore, required this.isLoadingMore});

  final List<TaskEntity> items;
  final bool hasMore;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(tasksListControllerProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.lg),
        itemCount: items.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              child: Center(
                child: isLoadingMore
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () => ref.read(tasksListControllerProvider.notifier).loadMore(),
                        child: const Text('Load more'),
                      ),
              ),
            );
          }

          final task = items[index];
          return TaskCard(task: task, onTap: () => context.push(AppRoutes.taskDetailsPath(task.id)));
        },
      ),
    );
  }
}

class _KanbanBoard extends ConsumerWidget {
  const _KanbanBoard({required this.items, required this.hasMore, required this.isLoadingMore});

  final List<TaskEntity> items;
  final bool hasMore;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byStatus = <String, List<TaskEntity>>{
      for (final status in _statusColumns) status: items.where((t) => t.status == status).toList(),
    };

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final status in _statusColumns)
                Expanded(child: _KanbanColumn(status: status, tasks: byStatus[status] ?? const [])),
            ],
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: isLoadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: () => ref.read(tasksListControllerProvider.notifier).loadMore(),
                    child: const Text('Load more tasks'),
                  ),
          ),
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({required this.status, required this.tasks});

  final String status;
  final List<TaskEntity> tasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                Text(_statusLabels[status]!, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: Spacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${tasks.length}', style: Theme.of(context).textTheme.labelSmall),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Text('Nothing here', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(Spacing.sm, 0, Spacing.sm, Spacing.sm),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskCard(task: task, onTap: () => context.push(AppRoutes.taskDetailsPath(task.id)));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
