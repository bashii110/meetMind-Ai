import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Future<({List<AppNotificationEntity> items, int unreadCount})> list() => _remote.list();

  @override
  Future<void> markRead(String id) => _remote.markRead(id);

  @override
  Future<void> markAllRead() => _remote.markAllRead();
}
