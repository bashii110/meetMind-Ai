import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/list_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';

final notificationRemoteDataSourceProvider = Provider(
  (ref) => NotificationRemoteDataSource(ref.watch(dioProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(ref.watch(notificationRemoteDataSourceProvider)),
);

final listNotificationsUseCaseProvider =
    Provider((ref) => ListNotificationsUseCase(ref.watch(notificationRepositoryProvider)));
final markNotificationReadUseCaseProvider =
    Provider((ref) => MarkNotificationReadUseCase(ref.watch(notificationRepositoryProvider)));
final markAllNotificationsReadUseCaseProvider =
    Provider((ref) => MarkAllNotificationsReadUseCase(ref.watch(notificationRepositoryProvider)));
