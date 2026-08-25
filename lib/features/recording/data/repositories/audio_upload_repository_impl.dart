import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:meetmind_ai/core/network/api_failure.dart';
import 'package:meetmind_ai/features/recording/domain/entities/pending_upload.dart';
import 'package:meetmind_ai/features/recording/domain/entities/recorded_audio.dart';
import 'package:meetmind_ai/features/recording/domain/repositories/audio_upload_repository.dart';
import 'package:meetmind_ai/features/recording/data/datasources/audio_upload_remote_data_source.dart';
import 'package:meetmind_ai/features/recording/data/datasources/pending_upload_local_data_source.dart';

class AudioUploadRepositoryImpl implements AudioUploadRepository {
  AudioUploadRepositoryImpl({
    required AudioUploadRemoteDataSource remote,
    required PendingUploadLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final AudioUploadRemoteDataSource _remote;
  final PendingUploadLocalDataSource _local;

  /// Matches the 512KB default documented in backend/README.md; the
  /// server caps each chunk at 10MB (`StoreAudioChunkRequest`), so there's
  /// plenty of headroom if this is ever raised.
  static const _chunkSizeBytes = 512 * 1024;

  @override
  Future<PendingUpload> enqueue({required String meetingId, required RecordedAudio audio}) async {
    final totalChunks = (audio.fileSizeBytes / _chunkSizeBytes).ceil().clamp(1, 1 << 30);
    final entry = PendingUpload(
      id: const Uuid().v4(),
      meetingId: meetingId,
      filePath: audio.filePath,
      extension: audio.extension,
      totalChunks: totalChunks,
      fileSizeBytes: audio.fileSizeBytes,
      durationSeconds: audio.duration.inSeconds,
      createdAt: DateTime.now(),
    );
    await _local.save(entry);
    return entry;
  }

  @override
  Future<void> upload(String pendingUploadId) async {
    var entry = await _local.get(pendingUploadId);
    if (entry == null) return;
    if (entry.status == PendingUploadStatus.uploaded) return;

    entry = entry.copyWith(status: PendingUploadStatus.uploading, errorMessage: null);
    await _local.save(entry);

    try {
      var remoteId = entry.remoteAudioFileId;
      if (remoteId == null) {
        final audioFile = await _remote.init(
          meetingId: entry.meetingId,
          totalChunks: entry.totalChunks,
          extension: entry.extension,
          mimeType: _mimeTypeFor(entry.extension),
          totalSize: entry.fileSizeBytes,
          durationSeconds: entry.durationSeconds,
        );
        remoteId = audioFile.id;
        entry = entry.copyWith(remoteAudioFileId: remoteId);
        await _local.save(entry);
      }

      // Reconcile with the server before sending anything — this is what
      // makes resuming after the app was killed mid-upload safe: we never
      // trust our own local "uploaded so far" record over the server's.
      final progress = await _remote.status(remoteId);
      final alreadyReceived = progress.receivedChunks.toSet();

      for (var index = 0; index < entry!.totalChunks; index++) {
        if (alreadyReceived.contains(index)) continue;

        final bytes = await _readChunk(entry!.filePath, index);
        await _remote.uploadChunk(
          audioFileId: remoteId,
          chunkIndex: index,
          bytes: bytes,
        );

        final uploaded = {...entry!.uploadedChunks, index}.toList()..sort();
        entry = entry.copyWith(uploadedChunks: uploaded);
        await _local.save(entry);
      }

      await _remote.complete(remoteId);

      entry = entry!.copyWith(status: PendingUploadStatus.uploaded);
      await _local.save(entry);

      // The server has the file now; no need to keep the local copy.
      final file = File(entry.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      await _local.save(entry!.copyWith(
        status: PendingUploadStatus.failed,
        errorMessage: ApiFailure.from(e).message,
      ));
      rethrow;
    }
  }

  @override
  Future<List<PendingUpload>> listForMeeting(String meetingId) async {
    final all = await _local.all();
    return all.where((u) => u.meetingId == meetingId).toList();
  }

  @override
  Future<List<PendingUpload>> listAll() => _local.all();

  @override
  Future<void> resumeAll() async {
    final all = await _local.all();
    for (final entry in all) {
      if (entry.status == PendingUploadStatus.uploaded) continue;
      try {
        await upload(entry.id);
      } catch (_) {
        // Already recorded on the entry itself (status: failed,
        // errorMessage) — keep going so one bad recording doesn't block
        // the rest of the queue from resuming.
      }
    }
  }

  @override
  Future<void> remove(String pendingUploadId) => _local.delete(pendingUploadId);

  Future<List<int>> _readChunk(String path, int index) async {
    final file = File(path);
    final length = await file.length();
    final start = index * _chunkSizeBytes;
    final end = (start + _chunkSizeBytes) > length ? length : start + _chunkSizeBytes;

    final bytes = <int>[];
    await for (final part in file.openRead(start, end)) {
      bytes.addAll(part);
    }
    return bytes;
  }

  String _mimeTypeFor(String extension) {
    switch (extension) {
      case 'wav':
        return 'audio/wav';
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
      case 'aac':
      default:
        return 'audio/m4a';
    }
  }
}
