import 'package:hive/hive.dart';

import '../../../../core/storage/local_db.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/task.dart';
import '../models/task_model.dart';

/// Hive cache of tasks — mirrors MeetingLocalDataSource's shape.
/// Comments/attachments aren't round-tripped through the cache (kept
/// empty on write); see PHASE10_README.md's known simplifications.
class TaskLocalDataSource {
  Box get _box => Hive.box(HiveBoxes.tasks);

  Future<void> save(TaskEntity task) => _box.put(task.id, _toJson(task));

  Future<void> saveAll(List<TaskEntity> tasks) async {
    await _box.putAll({for (final t in tasks) t.id: _toJson(t)});
  }

  TaskModel? getById(String id) {
    final raw = _box.get(id);
    return raw == null ? null : TaskModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  List<TaskModel> getAll() {
    return _box.values
        .map((raw) => TaskModel.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> delete(String id) => _box.delete(id);

  Map<String, dynamic> _toJson(TaskEntity t) => {
        'id': t.id,
        'workspace_id': t.workspaceId,
        'meeting_id': t.meetingId,
        'meeting_title': t.meetingTitle,
        'title': t.title,
        'description': t.description,
        'priority': t.priority,
        'status': t.status,
        'deadline': t.deadline?.toIso8601String(),
        'progress': t.progress,
        'is_overdue': t.isOverdue,
        'creator': t.creator != null ? _userJson(t.creator!) : null,
        'assignee': t.assignee != null ? _userJson(t.assignee!) : null,
        'comment_count': t.commentCount,
        'comments': const [],
        'attachments': const [],
        'created_at': t.createdAt.toIso8601String(),
        'updated_at': t.updatedAt?.toIso8601String(),
      };

  Map<String, dynamic> _userJson(AppUser user) => {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'email_verified': user.emailVerified,
        'role': user.role,
        'timezone': user.timezone,
        'avatar': user.avatar,
      };
}
