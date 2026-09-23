import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:meetmind_ai/features/notifications/domain/entities/app_notification.dart';
import 'package:meetmind_ai/features/notifications/presentation/providers/notifications_controller.dart';

import '../../../../../../core/network/api_failure.dart';
import '../../../../../../core/router/app_routes.dart';
import '../../../../../../core/theme/spacing.dart';
import '../../../../../../core/widgets/empty_state.dart';
import '../../../../../../core/widgets/skeleton_loader.dart';


class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  String _title(AppNotificationEntity n) {
    switch (n.type) {
      case 'meeting_invitation':
        final title = n.payload['meeting_title'] as String? ?? 'a meeting';
        final by = n.payload['invited_by_name'] as String? ?? 'Someone';
        return '$by invited you to "$title"';
      default:
        return n.type.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsControllerProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      // Phase 12 (DESIGN.md 4): a fading swap between loading/data states,
      // and a skeleton list instead of a bare spinner while loading.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: state.when(
          loading: () => const KeyedSubtree(key: ValueKey('loading'), child: SkeletonList()),
          error: (error, _) => KeyedSubtree(
            key: const ValueKey('error'),
            child: Center(child: Text(ApiFailure.from(error).message)),
          ),
          data: (data) {
            if (data.items.isEmpty) {
              return const KeyedSubtree(
                key: ValueKey('empty'),
                child: EmptyState(
                  icon: Icons.notifications_none,
                  title: 'No notifications yet',
                  message: "You'll see meeting invitations and updates here.",
                ),
              );
            }

            return KeyedSubtree(
              key: const ValueKey('data'),
              child: RefreshIndicator(
                onRefresh: () => ref.read(notificationsControllerProvider.notifier).refresh(),
                child: ListView.separated(
                  itemCount: data.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = data.items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: n.read
                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                            : Theme.of(context).colorScheme.tertiaryContainer,
                        child: Icon(
                          Icons.event_available,
                          color: n.read ? null : Theme.of(context).colorScheme.onTertiaryContainer,
                          size: 20,
                        ),
                      ),
                      title: Text(_title(n), style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.w600)),
                      subtitle: Text(DateFormat.yMMMd().add_jm().format(n.createdAt)),
                      onTap: () {
                        ref.read(notificationsControllerProvider.notifier).markRead(n.id);
                        final meetingId = n.payload['meeting_id'];
                        if (meetingId != null) {
                          context.push(AppRoutes.meetingDetailsPath(meetingId.toString()));
                        }
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
