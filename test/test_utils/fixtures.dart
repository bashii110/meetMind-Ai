import 'package:meetmind_ai/features/auth/domain/entities/app_user.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/meeting.dart';
import 'package:meetmind_ai/features/tasks/domain/entities/task.dart';

/// Small, hand-written test fixtures — no codegen/builder package, same
/// no-codegen convention this project uses everywhere else.
AppUser buildUser({
  String id = 'u1',
  String name = 'Ada Lovelace',
  String email = 'ada@example.com',
  String role = 'regular_user',
}) {
  return AppUser(
    id: id,
    name: name,
    email: email,
    emailVerified: true,
    role: role,
    timezone: 'UTC',
  );
}

TaskEntity buildTask({
  required String id,
  String title = 'Task',
  String status = 'pending',
  String priority = 'medium',
  int progress = 0,
  bool isOverdue = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return TaskEntity(
    id: id,
    workspaceId: 'w1',
    title: title,
    priority: priority,
    status: status,
    progress: progress,
    isOverdue: isOverdue,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    updatedAt: updatedAt,
  );
}

Meeting buildMeeting({
  required String id,
  String title = 'Meeting',
  String status = 'scheduled',
  String priority = 'medium',
  DateTime? date,
}) {
  return Meeting(
    id: id,
    workspaceId: 'w1',
    title: title,
    date: date ?? DateTime.utc(2026, 1, 1),
    priority: priority,
    status: status,
  );
}
