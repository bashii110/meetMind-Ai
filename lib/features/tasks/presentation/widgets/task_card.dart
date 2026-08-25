import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/priority_indicator.dart';
import '../../domain/entities/task.dart';
import 'deadline_chip.dart';

/// DESIGN.md 3.7: "Task card: title, assignee avatar, priority color-strip,
/// deadline countdown chip." Shared between the Kanban board and the
/// mobile grouped list (TaskListScreen).
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onTap});

  final TaskEntity task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final assignee = task.assignee;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (task.meetingTitle != null) ...[
                const SizedBox(height: Spacing.xs),
                Row(
                  children: [
                    Icon(Icons.event_note_outlined, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.meetingTitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: Spacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PriorityIndicator(priority: task.priority),
                  if (assignee != null)
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        assignee.name.isNotEmpty ? assignee.name[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 11, color: scheme.onPrimaryContainer),
                      ),
                    )
                  else
                    Icon(Icons.person_off_outlined, size: 18, color: scheme.outline),
                ],
              ),
              if (task.deadline != null) ...[
                const SizedBox(height: Spacing.sm),
                DeadlineChip(deadline: task.deadline!, isOverdue: task.isOverdue),
              ],
              if (task.progress > 0) ...[
                const SizedBox(height: Spacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: task.progress / 100,
                    minHeight: 4,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
