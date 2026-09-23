import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../sync/outbox_sync_manager.dart';

/// Small app-bar affordance surfacing offline-sync state — DESIGN.md 6's
/// shared-widget-library convention (a `StatusChip`-style pill), scoped
/// to sync specifically. Shows nothing once there's nothing queued and
/// nothing to review, same "quietly disappears" pattern the dashboard's
/// task-stats section already uses for its own non-fatal states.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(outboxSyncManagerProvider);

    if (sync.isSyncing) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (sync.conflictCount > 0) {
      return IconButton(
        tooltip: '${sync.conflictCount} task${sync.conflictCount == 1 ? '' : 's'} need review',
        icon: Badge(
          label: Text('${sync.conflictCount}'),
          child: const Icon(Icons.sync_problem),
        ),
        onPressed: () => context.push(AppRoutes.syncConflicts),
      );
    }

    if (sync.pendingCount > 0) {
      return IconButton(
        tooltip: '${sync.pendingCount} change${sync.pendingCount == 1 ? '' : 's'} waiting to sync',
        icon: Badge(
          label: Text('${sync.pendingCount}'),
          child: const Icon(Icons.cloud_upload_outlined),
        ),
        onPressed: () => ref.read(outboxSyncManagerProvider.notifier).syncNow(),
      );
    }

    return const SizedBox.shrink();
  }
}
