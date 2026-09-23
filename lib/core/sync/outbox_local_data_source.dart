import 'package:hive/hive.dart';

import '../storage/local_db.dart';
import 'outbox_entry.dart';

/// Hive-backed FIFO queue of [OutboxEntry]s — same hand-written-JSON-in-
/// a-Box convention as PendingUploadLocalDataSource (Phase 3).
class OutboxLocalDataSource {
  Box get _box => Hive.box(HiveBoxes.outbox);

  Future<void> add(OutboxEntry entry) => _box.put(entry.id, entry.toJson());

  Future<void> update(OutboxEntry entry) => _box.put(entry.id, entry.toJson());

  Future<void> remove(String id) => _box.delete(id);

  /// Oldest first, so replay preserves the order the user made changes in
  /// — later entries (e.g. a status change) can depend on earlier ones
  /// (the create that produced the real server id).
  List<OutboxEntry> all() {
    final entries = _box.values
        .map((raw) => OutboxEntry.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  int get pendingCount => _box.length;
}
