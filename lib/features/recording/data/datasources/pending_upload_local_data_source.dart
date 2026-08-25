import 'package:hive_flutter/hive_flutter.dart';
import 'package:meetmind_ai/features/recording/domain/entities/pending_upload.dart';
import '../../../../../../core/storage/local_db.dart';

/// Persists the pending-upload queue in the `pending_uploads_box` Hive box
/// (opened eagerly in `core/storage/local_db.dart` since recording depends
/// on it from app start). Stores plain `Map<String, dynamic>` values —
/// Hive supports Maps/Lists/primitives natively, so no generated
/// TypeAdapter is needed, consistent with this project's existing
/// hand-written `toJson`/`fromJson` convention everywhere else.
class PendingUploadLocalDataSource {
  Box get _box => Hive.box(HiveBoxes.pendingUploads);

  Future<void> save(PendingUpload upload) async {
    await _box.put(upload.id, upload.toJson());
  }

  Future<PendingUpload?> get(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return PendingUpload.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<List<PendingUpload>> all() async {
    final entries = _box.values
        .map((raw) => PendingUpload.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
