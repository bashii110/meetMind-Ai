import 'package:equatable/equatable.dart';

/// FR-9.x. Mirrors backend/app/Models/AppNotification (kept as "payload",
/// a loosely-typed map, since notification shapes vary by `type` and this
/// is only Phase 2's basic in-app list — richer per-type rendering can
/// come later without a schema change).
class AppNotificationEntity extends Equatable {
  const AppNotificationEntity({
    required this.id,
    required this.type,
    required this.payload,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final bool read;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, type, payload, read, createdAt];
}
