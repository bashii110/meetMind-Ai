import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../features/meetings/data/datasources/meeting_local_data_source.dart';
import '../../features/meetings/data/datasources/meeting_remote_data_source.dart';
import '../../features/meetings/presentation/providers/meeting_providers.dart';
import '../../features/meetings/presentation/providers/meetings_list_controller.dart';
import '../../features/tasks/data/datasources/task_local_data_source.dart';
import '../../features/tasks/data/datasources/task_remote_data_source.dart';
import '../../features/tasks/domain/entities/task.dart';
import '../../features/tasks/presentation/providers/task_providers.dart';
import '../../features/tasks/presentation/providers/tasks_list_controller.dart';
import 'conflict_local_data_source.dart';
import 'outbox_entry.dart';
import 'outbox_local_data_source.dart';
import 'sync_conflict.dart';

const _uuid = Uuid();

class SyncState {
  const SyncState({
    required this.pendingCount,
    required this.conflictCount,
    this.isSyncing = false,
    this.lastError,
  });

  final int pendingCount;
  final int conflictCount;
  final bool isSyncing;
  final String? lastError;

  SyncState copyWith({int? pendingCount, int? conflictCount, bool? isSyncing, String? lastError}) {
    return SyncState(
      pendingCount: pendingCount ?? this.pendingCount,
      conflictCount: conflictCount ?? this.conflictCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastError: lastError,
    );
  }
}

/// Replays the offline outbox against the backend once connectivity is
/// back — ARCHITECTURE.md 2.3. Deliberately NOT autoDispose: like
/// AudioUploadManager (Phase 3), a sync pass in progress must survive the
/// user navigating around the app.
///
/// Conflict policy: meetings use last-write-wins — a queued meeting
/// mutation is applied over whatever the server has, no questions asked.
/// Tasks use manual merge — a queued task *update* is only applied if the
/// server's `updated_at` hasn't moved past the moment the offline edit
/// was made; if it has, the mutation is pulled out of the queue and
/// turned into a [SyncConflict] for the user to resolve instead of
/// silently overwriting someone else's change.
class OutboxSyncManager extends Notifier<SyncState> {
  final _outboxLocal = OutboxLocalDataSource();
  final _conflictLocal = ConflictLocalDataSource();
  final _meetingLocal = MeetingLocalDataSource();
  final _taskLocal = TaskLocalDataSource();

  bool _running = false;

  @override
  SyncState build() {
    return SyncState(
      pendingCount: _outboxLocal.pendingCount,
      conflictCount: _conflictLocal.count,
    );
  }

  void _refreshCounts() {
    state = state.copyWith(
      pendingCount: _outboxLocal.pendingCount,
      conflictCount: _conflictLocal.count,
    );
  }

  Future<void> syncNow() async {
    if (_running) return;
    _running = true;
    state = state.copyWith(isSyncing: true, lastError: null);

    final meetingRemote = ref.read(meetingRemoteDataSourceProvider);
    final taskRemote = ref.read(taskRemoteDataSourceProvider);
    // Temp local id -> real server id, built up as creates succeed during
    // this pass, so a later entry for the same not-yet-synced entity
    // (e.g. a status change right after an offline create) resolves to
    // the right target.
    final idRemap = <String, String>{};
    String resolve(String id) => idRemap[id] ?? id;

    try {
      for (final entry in _outboxLocal.all()) {
        try {
          switch (entry.entityType) {
            case OutboxEntityType.meeting:
              await _replayMeeting(entry, meetingRemote, resolve, idRemap);
              break;
            case OutboxEntityType.task:
              await _replayTask(entry, taskRemote, resolve, idRemap);
              break;
          }
          await _outboxLocal.remove(entry.id);
        } catch (e) {
          // Leave it queued and stop this pass — a later entry might
          // depend on this one, so retrying out of order risks a worse
          // state than just waiting for the next sync trigger.
          await _outboxLocal.update(entry.copyWith(
            retryCount: entry.retryCount + 1,
            lastError: e.toString(),
          ));
          state = state.copyWith(lastError: e.toString());
          break;
        }
      }
    } finally {
      _running = false;
      state = state.copyWith(isSyncing: false);
      _refreshCounts();
      // Best-effort: whatever's currently on screen picks up fresh data,
      // same convention AudioUploadManager and every *ListController use.
      ref.read(meetingsListControllerProvider.notifier).refresh();
      ref.read(tasksListControllerProvider.notifier).refresh();
    }
  }

  Future<void> _replayMeeting(
    OutboxEntry entry,
    MeetingRemoteDataSource remote,
    String Function(String) resolve,
    Map<String, String> idRemap,
  ) async {
    switch (entry.operation) {
      case OutboxOperation.create:
        final created = await remote.create(entry.payload);
        idRemap[entry.localId] = created.id;
        await _meetingLocal.delete(entry.localId);
        await _meetingLocal.save(created);
        break;
      case OutboxOperation.update:
        final updated = await remote.update(resolve(entry.localId), entry.payload);
        await _meetingLocal.save(updated);
        break;
      case OutboxOperation.changeStatus:
        final updated = await remote.changeStatus(resolve(entry.localId), entry.payload['status'] as String);
        await _meetingLocal.save(updated);
        break;
      case OutboxOperation.delete:
        final id = entry.localId;
        // A temp id that never got a matching create synced this pass
        // has nothing on the server to delete.
        if (!(id.startsWith('local_') && !idRemap.containsKey(id))) {
          await remote.delete(resolve(id));
        }
        await _meetingLocal.delete(id);
        break;
    }
  }

  Future<void> _replayTask(
    OutboxEntry entry,
    TaskRemoteDataSource remote,
    String Function(String) resolve,
    Map<String, String> idRemap,
  ) async {
    switch (entry.operation) {
      case OutboxOperation.create:
        final created = await remote.create(entry.payload);
        idRemap[entry.localId] = created.id;
        await _taskLocal.delete(entry.localId);
        await _taskLocal.save(created);
        break;
      case OutboxOperation.update:
        final id = resolve(entry.localId);
        final server = await remote.getById(id);
        final baseline = entry.baseUpdatedAt;
        final diverged =
            baseline != null && server.updatedAt != null && server.updatedAt!.isAfter(baseline);

        if (diverged) {
          await _conflictLocal.add(SyncConflict(
            id: _uuid.v4(),
            taskId: id,
            localChanges: entry.payload,
            serverSnapshot: _taskToJson(server),
            detectedAt: DateTime.now(),
          ));
          // Keep the server's copy locally until the user resolves it —
          // don't let the stale offline edit linger in the cache.
          await _taskLocal.save(server);
          break;
        }

        final updated = await remote.update(id, entry.payload);
        await _taskLocal.save(updated);
        break;
      case OutboxOperation.changeStatus:
        final updated = await remote.changeStatus(resolve(entry.localId), entry.payload['status'] as String);
        await _taskLocal.save(updated);
        break;
      case OutboxOperation.delete:
        final id = entry.localId;
        if (!(id.startsWith('local_') && !idRemap.containsKey(id))) {
          await remote.delete(resolve(id));
        }
        await _taskLocal.delete(id);
        break;
    }
  }

  Map<String, dynamic> _taskToJson(TaskEntity task) => {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'priority': task.priority,
        'status': task.status,
        'deadline': task.deadline?.toIso8601String(),
        'meeting_id': task.meetingId,
        'updated_at': task.updatedAt?.toIso8601String(),
      };

  /// [keepLocal] true re-applies the offline edit over the server's
  /// current copy; false discards it and leaves the server's version
  /// (already cached during conflict detection) as-is.
  Future<void> resolveConflict(String conflictId, {required bool keepLocal}) async {
    final conflict = _conflictLocal.all().firstWhere((c) => c.id == conflictId);

    if (keepLocal) {
      final taskRemote = ref.read(taskRemoteDataSourceProvider);
      final updated = await taskRemote.update(conflict.taskId, conflict.localChanges);
      await _taskLocal.save(updated);
    }

    await _conflictLocal.remove(conflictId);
    _refreshCounts();
    ref.read(tasksListControllerProvider.notifier).refresh();
  }

  List<SyncConflict> get conflicts => _conflictLocal.all();
}

final outboxSyncManagerProvider = NotifierProvider<OutboxSyncManager, SyncState>(OutboxSyncManager.new);
