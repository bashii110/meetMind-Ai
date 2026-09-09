import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/error_feedback.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/admin_user.dart';
import '../providers/admin_users_controller.dart';
import '../providers/moderation_queue_controller.dart';
import '../providers/platform_stats_controller.dart';
import '../widgets/admin_user_tile.dart';
import '../widgets/moderation_item_tile.dart';

/// SRD FR-16.x / PHASES.md Phase 9: platform governance. Client-side
/// gated to `AppUser.role == 'system_admin'` — real enforcement is the
/// backend Policy on every /admin/* endpoint (ARCHITECTURE.md section 6);
/// this check just avoids showing the screen to people who'd get 403s.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authControllerProvider).valueOrNull;

    if (currentUser?.role != 'system_admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: Spacing.md),
                Text(
                  "You don't have access to this area.",
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Moderation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _OverviewTab(),
          _UsersTab(currentUserId: currentUser!.id),
          const _ModerationTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(platformStatsControllerProvider);

    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
      data: (s) => RefreshIndicator(
        onRefresh: () => ref.read(platformStatsControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Spacing.md,
              crossAxisSpacing: Spacing.md,
              childAspectRatio: 1.6,
              children: [
                _StatTile(label: 'Users', value: '${s.totalUsers}', icon: Icons.people_outline),
                _StatTile(label: 'Active users', value: '${s.activeUsers}', icon: Icons.person_pin_outlined),
                _StatTile(label: 'Workspaces', value: '${s.totalWorkspaces}', icon: Icons.workspaces_outlined),
                _StatTile(label: 'Meetings', value: '${s.totalMeetings}', icon: Icons.event_outlined),
                _StatTile(label: 'Tasks', value: '${s.totalTasks}', icon: Icons.checklist_outlined),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            Text('Storage usage', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: s.storageUsageRatio,
                minHeight: 10,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              '${s.storageUsedGb.toStringAsFixed(1)} GB of ${s.storageLimitGb.toStringAsFixed(0)} GB used',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: scheme.primary, size: 20),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab({required this.currentUserId});

  final String currentUserId;

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmToggle(BuildContext context, AdminUser user) async {
    final disabling = !user.isDisabled;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(disabling ? 'Disable account?' : 'Re-enable account?'),
        content: Text(
          disabling
              ? '${user.name} will no longer be able to sign in.'
              : '${user.name} will be able to sign in again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(disabling ? 'Disable' : 'Enable')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await runOrNotify(
      context,
      () => ref.read(adminUsersControllerProvider.notifier).toggleDisabled(user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Search users', prefixIcon: Icon(Icons.search)),
            onSubmitted: (value) => ref.read(adminUsersControllerProvider.notifier).applySearch(value.trim()),
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
            data: (s) {
              if (s.items.isEmpty) {
                return Center(
                  child: Text(
                    'No users found.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(adminUsersControllerProvider.notifier).refresh(),
                child: ListView.builder(
                  itemCount: s.items.length + (s.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= s.items.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                        child: Center(
                          child: s.isLoadingMore
                              ? const CircularProgressIndicator()
                              : TextButton(
                                  onPressed: () => ref.read(adminUsersControllerProvider.notifier).loadMore(),
                                  child: const Text('Load more'),
                                ),
                        ),
                      );
                    }
                    final user = s.items[index];
                    final isSelf = user.id == widget.currentUserId;
                    return AdminUserTile(
                      user: user,
                      // An admin can't disable their own account from
                      // here — that would lock them out of the screen
                      // they're using to manage everyone else's.
                      onToggleDisabled: isSelf ? null : () => _confirmToggle(context, user),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModerationTab extends ConsumerWidget {
  const _ModerationTab();

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove content?'),
        content: const Text('This deletes the reported content. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await runOrNotify(
      context,
      () => ref.read(moderationQueueControllerProvider.notifier).resolve(itemId, remove: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moderationQueueControllerProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
      data: (s) {
        if (s.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt, size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'Nothing to review right now.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(moderationQueueControllerProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            itemCount: s.items.length + (s.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= s.items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  child: Center(
                    child: s.isLoadingMore
                        ? const CircularProgressIndicator()
                        : TextButton(
                            onPressed: () => ref.read(moderationQueueControllerProvider.notifier).loadMore(),
                            child: const Text('Load more'),
                          ),
                  ),
                );
              }
              final item = s.items[index];
              return ModerationItemTile(
                item: item,
                onDismiss: () => runOrNotify(
                  context,
                  () => ref.read(moderationQueueControllerProvider.notifier).resolve(item.id, remove: false),
                ),
                onRemove: () => _confirmRemove(context, ref, item.id),
              );
            },
          ),
        );
      },
    );
  }
}
