import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_notification.dart';
import 'notification_providers.dart';

class NotificationsState {
  const NotificationsState({required this.items, required this.unreadCount});

  final List<AppNotificationEntity> items;
  final int unreadCount;
}

class NotificationsController extends AsyncNotifier<NotificationsState> {
  @override
  Future<NotificationsState> build() async {
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
