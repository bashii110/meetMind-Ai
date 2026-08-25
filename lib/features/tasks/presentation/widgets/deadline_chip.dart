import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// DESIGN.md 3.7: "deadline countdown chip." Red once overdue (mirrors the
/// backend's Task::isOverdue), amber inside the next 24h, neutral
/// otherwise.
class DeadlineChip extends StatelessWidget {
  const DeadlineChip({super.key, required this.deadline, this.isOverdue = false});

  final DateTime deadline;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final dueSoon = !isOverdue && deadline.difference(DateTime.now()) <= const Duration(hours: 24);
    final scheme = Theme.of(context).colorScheme;

    final Color color = isOverdue ? scheme.error : (dueSoon ? const Color(0xFFFF9800) : scheme.onSurfaceVariant);
    final String label =
        isOverdue ? 'Overdue · ${DateFormat.MMMd().format(deadline)}' : DateFormat.MMMd().add_jm().format(deadline);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
