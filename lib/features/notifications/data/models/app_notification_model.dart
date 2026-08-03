import '../../domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotificationEntity {
  const AppNotificationModel({
    required super.id,
    required super.type,
    required super.payload,
    required super.read,
    required super.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'].toString(),
      type: json['type'] as String? ?? 'unknown',
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
