import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/moderation_item.dart';

/// SRD FR-16.3.
class ModerationItemTile extends StatelessWidget {
  const ModerationItemTile({
    super.key,
    required this.item,
    required this.onDismiss,
    required this.onRemove,
  });

  final ModerationItem item;
  final VoidCallback onDismiss;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 16, color: scheme.error),
                const SizedBox(width: 6),
                Text(
                  item.contentType.replaceAll('_', ' '),
                  style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const Spacer(),
                Text(DateFormat.yMMMd().format(item.reportedAt), style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.contentSnippet, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(
              'Reported by ${item.reportedByName} · ${item.reason}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: onRemove,
                  style: FilledButton.styleFrom(foregroundColor: scheme.error),
                  child: const Text('Remove content'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
