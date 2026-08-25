import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/audio_upload_local_data_source.dart';
import '../../data/datasources/audio_upload_remote_data_source.dart';
import '../../data/models/audio_upload_model.dart';
import '../../domain/entities/audio_upload.dart';

const _maxAttemptsPerChunk = 3;
const _retryDelays = [Duration(seconds: 1), Duration(seconds: 3), Duration(seconds: 6)];

/// Deliberately NOT autoDispose: recording a meeting and then navigating
/// away (DESIGN.md 3.5: "users can navigate away without losing progress")
/// must not cancel an in-flight upload. This provider lives for the app's
/// whole session; state is also persisted to Hive so it survives a full
/// app restart too.
class AudioUploadManager extends Notifier<Map<String, AudioUpload>> {
  final _localDataSource = AudioUploadLocalDataSource();
  final _inFlight = <String>{};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  Map<String, AudioUpload> build() {
    final existing = <String, AudioUpload>{
      for (final u in _localDataSource.getAll()) u.localId: u,
    };

    // Resume anything left mid-upload from a previous session.
    for (final upload in existing.values) {
      if (upload.status != AudioUploadStatus.uploaded) {
        scheduleMicrotask(() => _process(upload.localId));
      }
    }

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        resumeAll();
      }
    });
    ref.onDispose(() => _connectivitySub?.cancel());

    return existing;
  }

  Future<void> enqueue({
    required String meetingId,
    required String filePath,
    required int durationSeconds,
  }) async {
    final upload = AudioUploadModel(
      localId: DateTime.now().microsecondsSinceEpoch.toString(),
      meetingId: meetingId,
      filePath: filePath,
      durationSeconds: durationSeconds,
      status: AudioUploadStatus.pendingUpload,
      createdAt: DateTime.now(),
    );

    await _localDataSource.save(upload);
    state = {...state, upload.localId: upload};
    unawaited(_process(upload.localId));
  }

  void resumeAll() {
    for (final upload in state.values) {
      if (upload.status == AudioUploadStatus.pendingUpload || upload.status == AudioUploadStatus.failed) {
        unawaited(_process(upload.localId));
      }
    }
  }

  Future<void> retry(String localId) => _process(localId);

  Future<void> _process(String localId) async {
    if (_inFlight.contains(localId)) return;
    _inFlight.add(localId);

    try {
      await _processInner(localId);
    } finally {
      _inFlight.remove(localId);
    }
  }

  Future<void> _processInner(String localId) async {
    final initial = _localDataSource.getById(localId);
    if (initial == null || initial.status == AudioUploadStatus.uploaded) return;

    final online = await _isOnline();
    if (!online) {
      await _update(initial.copyWith(status: AudioUploadStatus.pendingUpload));
      return;
    }

    // Declared as the base entity type (not AudioUploadModel) because
    // AudioUpload.copyWith() returns AudioUpload — reassigning a `var`
    // inferred as AudioUploadModel to that result would be a type error.
    AudioUpload upload = initial.copyWith(status: AudioUploadStatus.uploading);
    await _update(upload);

    try {
      final file = File(upload.filePath);
      final bytes = await file.readAsBytes();
      final totalChunks = bytes.isEmpty ? 1 : (bytes.length / upload.chunkSizeBytes).ceil();

      final remote = ref.read(audioUploadRemoteDataSourceProvider);

      var serverAudioFileId = upload.serverAudioFileId;
      serverAudioFileId ??= (await remote.init(
        meetingId: upload.meetingId,
        totalChunks: totalChunks,
        totalSize: bytes.length,
        durationSeconds: upload.durationSeconds, extension: '',
      )) as String?;
      upload = upload.copyWith(serverAudioFileId: serverAudioFileId, totalChunks: totalChunks);
      await _update(upload);

      // Server is the source of truth for what it's actually stored —
      // more reliable than trusting local state alone if the app was
      // killed mid-write.
      final received = (await remote.status(serverAudioFileId!)).receivedChunks.toSet();

      for (var index = 0; index < totalChunks; index++) {
        if (received.contains(index)) continue;

        final start = index * upload.chunkSizeBytes;
        final rawEnd = (index + 1) * upload.chunkSizeBytes;
        final end = rawEnd > bytes.length ? bytes.length : rawEnd;
        final chunk = Uint8List.sublistView(bytes, start, end);

        final uploaded = await _uploadChunkWithRetry(
          remote: remote,
          audioFileId: serverAudioFileId,
          index: index,
          bytes: chunk,
        );

        if (!uploaded) {
          upload = upload.copyWith(
            status: AudioUploadStatus.failed,
            uploadedChunkIndexes: received.toList()..sort(),
          );
          await _update(upload);
          return;
        }

        received.add(index);
        upload = upload.copyWith(uploadedChunkIndexes: received.toList()..sort());
        await _update(upload);
      }

      await remote.complete(serverAudioFileId);
      upload = upload.copyWith(status: AudioUploadStatus.uploaded);
      await _update(upload);
    } catch (_) {
      await _update(upload.copyWith(status: AudioUploadStatus.failed));
    }
  }

  Future<bool> _uploadChunkWithRetry({
    required AudioUploadRemoteDataSource remote,
    required String audioFileId,
    required int index,
    required Uint8List bytes,
  }) async {
    for (var attempt = 0; attempt < _maxAttemptsPerChunk; attempt++) {
      try {
        await remote.uploadChunk(audioFileId: audioFileId, chunkIndex: index, bytes: bytes);
        return true;
      } catch (_) {
        if (attempt < _maxAttemptsPerChunk - 1) {
          await Future.delayed(_retryDelays[attempt]);
        }
      }
    }
    return false;
  }

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _update(AudioUpload upload) async {
    final model = AudioUploadModel.fromEntity(upload);
    await _localDataSource.save(model);
    state = {...state, upload.localId: upload};
  }
}

final audioUploadRemoteDataSourceProvider = Provider(
  (ref) => AudioUploadRemoteDataSource(ref.watch(dioProvider)),
);

final audioUploadManagerProvider = NotifierProvider<AudioUploadManager, Map<String, AudioUpload>>(
  AudioUploadManager.new,
);
