import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/avatar_stack.dart';
import '../../../../core/widgets/priority_indicator.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/meeting.dart';

class MeetingCard extends StatelessWidget {
  const MeetingCard({super.key, required this.meeting, required this.onTap});

  final Meeting meeting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd().format(meeting.date);
    final names = meeting.participants.map((p) => p.name).toList();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meeting.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(status: meeting.status),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                meeting.time != null ? '$dateLabel · ${meeting.time}' : dateLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PriorityIndicator(priority: meeting.priority),
                  if (names.isNotEmpty) AvatarStack(names: names, radius: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
