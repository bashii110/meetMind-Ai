import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class ListNotificationsUseCase {
  const ListNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Future<({List<AppNotificationEntity> items, int unreadCount})> call() => _repository.list();
}
