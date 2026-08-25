import 'package:hive/hive.dart';

import '../../../../core/storage/local_db.dart';
import '../models/audio_upload_model.dart';

/// Wraps the Hive box directly — no repository interface needed for this
/// side, since "local persistence of the upload queue" IS the concern
/// (unlike other features where a repository picks between local cache and
/// remote API, there's no remote equivalent of "list my queued uploads").
class AudioUploadLocalDataSource {
  Box<String> get _box => Hive.box<String>(HiveBoxes.audioUploads);

  List<AudioUploadModel> getAll() {
    return _box.values.map(AudioUploadModel.decode).toList();
  }

  AudioUploadModel? getById(String localId) {
    final raw = _box.get(localId);
    return raw == null ? null : AudioUploadModel.decode(raw);
  }

  Future<void> save(AudioUploadModel upload) => _box.put(upload.localId, upload.encode());

  Future<void> delete(String localId) => _box.delete(localId);
}
