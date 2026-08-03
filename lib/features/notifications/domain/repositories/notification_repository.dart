import '../entities/app_notification.dart';

abstract interface class NotificationRepository {
  Future<({List<AppNotificationEntity> items, int unreadCount})> list();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}
