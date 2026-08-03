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

/// DESIGN.md 3.3's Home Dashboard. Phase 2 adds the meetings section now
/// that meetings exist; the stat row, AI summaries list, calendar widget,
/// and insights card described in DESIGN.md land with the phases that
/// produce that data (Phase 4-6).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final meetings = ref.watch(meetingsListControllerProvider);
    final notifications = ref.watch(notificationsControllerProvider);
    final unreadCount = notifications.valueOrNull?.unreadCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MeetMind AI'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
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
          ],
        ),
      ),
    );
  }
}
