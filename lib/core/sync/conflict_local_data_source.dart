import 'package:hive/hive.dart';

import '../storage/local_db.dart';
import 'sync_conflict.dart';

class ConflictLocalDataSource {
  Box get _box => Hive.box(HiveBoxes.syncConflicts);

  Future<void> add(SyncConflict conflict) => _box.put(conflict.id, conflict.toJson());

  Future<void> remove(String id) => _box.delete(id);

  List<SyncConflict> all() {
    final list = _box.values
        .map((raw) => SyncConflict.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
    list.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return list;
  }

  int get count => _box.length;
}
