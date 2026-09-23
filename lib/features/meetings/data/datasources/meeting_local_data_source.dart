import 'package:hive/hive.dart';

import '../../../../core/storage/local_db.dart';
import '../../domain/entities/meeting.dart';
import '../models/meeting_model.dart';

/// Hive cache of meetings — ARCHITECTURE.md 2.3's "local source of
/// truth." Meetings are cached individually, keyed by id, so a detail
/// screen can read one without deserializing the whole list;
/// MeetingRepositoryImpl reads the full cache via [getAll] when offline.
///
/// Participants aren't round-tripped through the cache (kept empty on
/// write) — an offline fallback showing a meeting without its invite
/// list is an acceptable trade-off for this phase; see
/// PHASE10_README.md.
class MeetingLocalDataSource {
  Box get _box => Hive.box(HiveBoxes.meetings);

  Future<void> save(Meeting meeting) => _box.put(meeting.id, _toJson(meeting));

  Future<void> saveAll(List<Meeting> meetings) async {
    await _box.putAll({for (final m in meetings) m.id: _toJson(m)});
  }

  MeetingModel? getById(String id) {
    final raw = _box.get(id);
    return raw == null ? null : MeetingModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  List<MeetingModel> getAll() {
    return _box.values
        .map((raw) => MeetingModel.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> delete(String id) => _box.delete(id);

  Map<String, dynamic> _toJson(Meeting m) => {
        'id': m.id,
        'workspace_id': m.workspaceId,
        'title': m.title,
        'description': m.description,
        'date': m.date.toIso8601String().split('T').first,
        'time': m.time,
        'location': m.location,
        'online_link': m.onlineLink,
        'priority': m.priority,
        'category': m.category,
        'status': m.status,
        'owner': m.ownerId != null ? {'id': m.ownerId, 'name': m.ownerName} : null,
        'tags': m.tags.map((t) => {'name': t}).toList(),
        'participants': const [],
        'participant_count': m.participantCount,
      };
}
