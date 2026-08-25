import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/auth/presentation/providers/auth_controller.dart';
import 'package:meetmind_ai/features/notifications/domain/entities/app_notification.dart';
import 'package:meetmind_ai/features/notifications/presentation/providers/notification_providers.dart';


class NotificationsState {
  const NotificationsState({required this.items, required this.unreadCount});

  final List<AppNotificationEntity> items;
  final int unreadCount;
}

class NotificationsController extends AsyncNotifier<NotificationsState> {
  @override
  Future<NotificationsState> build() async {
    // Rebuild whenever the signed-in user changes (login, logout, or a
    // different account logging in afterwards). This provider is
    // intentionally NOT autoDispose, which means without this dependency
    // it would keep serving the *previous* user's cached notifications
    // after a logout/login switch.
    ref.watch(authControllerProvider.select((state) => state.valueOrNull?.id));
    final result = await ref.read(listNotificationsUseCaseProvider)();
    return NotificationsState(items: result.items, unreadCount: result.unreadCount);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(listNotificationsUseCaseProvider)();
      return NotificationsState(items: result.items, unreadCount: result.unreadCount);
    });
  }

  Future<void> markRead(String id) async {
    await ref.read(markNotificationReadUseCaseProvider)(id);
    await refresh();
  }

  Future<void> markAllRead() async {
    await ref.read(markAllNotificationsReadUseCaseProvider)();
    await refresh();
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, NotificationsState>(NotificationsController.new);
