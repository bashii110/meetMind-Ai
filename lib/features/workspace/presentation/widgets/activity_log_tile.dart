import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/activity_log_entry.dart';

/// SRD FR-10.4. Renders one line of the workspace activity timeline —
/// prefers the backend's pre-built `ActivityLogEntry.description` over
/// constructing a sentence from `ActivityLogEntry.action` client-side,
/// since the backend has the full context of what happened.
class ActivityLogTile extends StatelessWidget {
  const ActivityLogTile({super.key, required this.entry});

  final ActivityLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        child: Text(entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?'),
      ),
      title: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: entry.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: ' ${entry.description ?? entry.action.replaceAll('_', ' ')}'),
          ],
        ),
      ),
      subtitle: Text(
        DateFormat.yMMMd().add_jm().format(entry.createdAt),
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
      ),
    );
  }
}
