import 'package:dio/dio.dart';

import '../models/app_notification_model.dart';

class NotificationRemoteDataSource {
  const NotificationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({List<AppNotificationModel> items, int unreadCount})> list() async {
    final response = await _dio.get('/notifications');
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List? ?? const [])
        .map((e) => AppNotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, unreadCount: data['unread_count'] as int? ?? 0);
  }

  Future<void> markRead(String id) => _dio.post('/notifications/$id/read');

  Future<void> markAllRead() => _dio.post('/notifications/read-all');
}
