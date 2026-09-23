import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/outbox_sync_manager.dart';
import '../../../../core/sync/sync_conflict.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/error_feedback.dart';

/// Manual-merge resolution for task edits that diverged from the server
/// while offline — this project's documented policy: meetings use
/// last-write-wins and never reach this screen; only tasks do.
class ConflictResolutionScreen extends ConsumerWidget {
  const ConflictResolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the sync state (rather than a separate conflicts stream)
    // is enough to rebuild this screen whenever the conflict count
    // changes, without a second source of truth to keep in sync.
    ref.watch(outboxSyncManagerProvider);
    final conflicts = ref.read(outboxSyncManagerProvider.notifier).conflicts;

    return Scaffold(
      appBar: AppBar(title: const Text('Review changes')),
      body: conflicts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: Spacing.md),
                    const Text('Nothing needs review right now.'),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(Spacing.lg),
              itemCount: conflicts.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.lg),
              itemBuilder: (context, index) => _ConflictCard(conflict: conflicts[index]),
            ),
    );
  }
}

class _ConflictCard extends ConsumerStatefulWidget {
  const _ConflictCard({required this.conflict});

  final SyncConflict conflict;

  @override
  ConsumerState<_ConflictCard> createState() => _ConflictCardState();
}

class _ConflictCardState extends ConsumerState<_ConflictCard> {
  bool _resolving = false;

  Future<void> _resolve(bool keepLocal) async {
    setState(() => _resolving = true);
    await runOrNotify(
      context,
      () => ref
          .read(outboxSyncManagerProvider.notifier)
          .resolveConflict(widget.conflict.id, keepLocal: keepLocal),
    );
    if (mounted) setState(() => _resolving = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final local = widget.conflict.localChanges;
    final server = widget.conflict.serverSnapshot;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync_problem, size: 18, color: scheme.error),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    (server['title'] as String?) ?? 'Task',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'This task changed on the server after you edited it offline.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: Spacing.md),
            _VersionBlock(label: 'Your offline changes', fields: local, scheme: scheme),
            const SizedBox(height: Spacing.sm),
            _VersionBlock(label: "Server's current version", fields: server, scheme: scheme),
            const SizedBox(height: Spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _resolving ? null : () => _resolve(false),
                  child: const Text('Keep server version'),
                ),
                const SizedBox(width: Spacing.sm),
                FilledButton(
                  onPressed: _resolving ? null : () => _resolve(true),
                  child: _resolving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Keep my changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionBlock extends StatelessWidget {
  const _VersionBlock({required this.label, required this.fields, required this.scheme});

  final String label;
  final Map<String, dynamic> fields;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final relevant =
        ['title', 'description', 'priority', 'deadline'].where((key) => fields[key] != null).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          if (relevant.isEmpty)
            const Text('(no visible field changes)', style: TextStyle(fontSize: 12))
          else
            for (final key in relevant)
              Text(
                '${key[0].toUpperCase()}${key.substring(1)}: ${fields[key]}',
                style: const TextStyle(fontSize: 12),
              ),
        ],
      ),
    );
  }
}
