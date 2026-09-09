import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../meetings/presentation/providers/meetings_list_controller.dart';
import '../../../meetings/presentation/widgets/meeting_card.dart';
import '../../../notifications/presentation/providers/notifications_controller.dart';
import '../../../tasks/presentation/providers/task_stats_provider.dart';

/// DESIGN.md 3.3's Home Dashboard. Phase 2 added the meetings section;
/// Phase 5 added the "Pending Tasks / Completed Tasks" stat row; Phase 6
/// added a calendar shortcut in the app bar; Phase 7 added a Workspaces
/// shortcut (SRD FR-10.1); Phase 8 added a global Search shortcut (SRD
/// FR-12.1). Phase 9 adds an Analytics shortcut for every signed-in user
/// (SRD FR-13.1/FR-2.5) and an Admin shortcut shown only to
/// `role == 'system_admin'` accounts (SRD FR-16.x) — regular users never
/// see the icon, since there's nothing behind it for them; `AdminScreen`
/// still re-checks the role itself as the real gate.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final meetings = ref.watch(meetingsListControllerProvider);
    final notifications = ref.watch(notificationsControllerProvider);
    final taskStats = ref.watch(taskStatsProvider);
    final unreadCount = notifications.valueOrNull?.unreadCount ?? 0;
    final isSystemAdmin = user?.role == 'system_admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('MeetMind AI'),
        actions: [
          // Search - keep visible
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
          ),

          // Notifications - keep visible
          IconButton(
            tooltip: 'Notifications',
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push(AppRoutes.notifications),
          ),

          // Profile - keep visible
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),

          // More menu
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'analytics':
                  context.push(AppRoutes.analytics);
                  break;

                case 'workspace':
                  context.push(AppRoutes.workspace);
                  break;

                case 'calendar':
                  context.push(AppRoutes.calendar);
                  break;

                case 'admin':
                  context.push(AppRoutes.admin);
                  break;

                case 'logout':
                  ref.read(authControllerProvider.notifier).logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'analytics',
                child: ListTile(
                  leading: Icon(Icons.insights_outlined),
                  title: Text('Analytics'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              const PopupMenuItem(
                value: 'workspace',
                child: ListTile(
                  leading: Icon(Icons.workspaces_outlined),
                  title: Text('Workspaces'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              const PopupMenuItem(
                value: 'calendar',
                child: ListTile(
                  leading: Icon(Icons.calendar_month_outlined),
                  title: Text('Calendar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              if (isSystemAdmin)
                const PopupMenuItem(
                  value: 'admin',
                  child: ListTile(
                    leading: Icon(Icons.admin_panel_settings_outlined),
                    title: Text('Admin'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

              const PopupMenuDivider(),

              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Log out'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.meetingNew),
        icon: const Icon(Icons.add),
        label: const Text('New meeting'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(meetingsListControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            if (user != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.lg),
                child: Text(
                  'Welcome back, ${user.name}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your meetings', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push(AppRoutes.meetings),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            meetings.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: Spacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                child: Text(
                  'Could not load meetings.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              data: (list) {
                if (list.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: Spacing.md),
                    child: EmptyState(
                      icon: Icons.event_busy,
                      title: 'No meetings yet',
                      message: 'Tap "New meeting" to schedule your first one.',
                    ),
                  );
                }

                final preview = list.items.take(3);
                return Column(
                  children: [
                    for (final meeting in preview)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: MeetingCard(
                          meeting: meeting,
                          onTap: () => context.push(AppRoutes.meetingDetailsPath(meeting.id)),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: Spacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your tasks', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push(AppRoutes.tasks),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            taskStats.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: Spacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              // Non-fatal — the tasks section just quietly disappears rather
              // than blocking the rest of the dashboard from rendering.
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => Row(
                children: [
                  Expanded(
                    child: _TaskStatCard(
                      label: 'Pending',
                      count: stats.pending,
                      icon: Icons.pending_actions_outlined,
                      onTap: () => context.push(AppRoutes.tasks),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: _TaskStatCard(
                      label: 'Completed',
                      count: stats.completed,
                      icon: Icons.task_alt_outlined,
                      onTap: () => context.push(AppRoutes.tasks),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// DESIGN.md 3.3: "Two-column stat row: Pending Tasks / Completed Tasks."
class _TaskStatCard extends StatelessWidget {
  const _TaskStatCard({required this.label, required this.count, required this.icon, required this.onTap});

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: Spacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count', style: Theme.of(context).textTheme.headlineSmall),
                  Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
