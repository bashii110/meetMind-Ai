import 'package:equatable/equatable.dart';

enum AudioUploadStatus { pendingUpload, uploading, uploaded, failed }

/// A locally-recorded meeting audio file and its upload progress.
/// Mirrors ARCHITECTURE.md 2.4's local status flow (pending_upload ->
/// uploaded) and is persisted to Hive so it survives app restarts —
/// see features/recording/data/models/audio_upload_model.dart.
class AudioUpload extends Equatable {
  const AudioUpload({
    required this.localId,
    required this.meetingId,
    required this.filePath,
    required this.durationSeconds,
    required this.status,
    this.serverAudioFileId,
    this.totalChunks,
    this.uploadedChunkIndexes = const [],
    this.chunkSizeBytes = 512 * 1024,
    required this.createdAt,
  });

  final String localId;
  final String meetingId;
  final String filePath;
  final int durationSeconds;
  final AudioUploadStatus status;

  /// Set once POST /meetings/{id}/recording/init succeeds.
  final String? serverAudioFileId;
  final int? totalChunks;
  final List<int> uploadedChunkIndexes;
  final int chunkSizeBytes;
  final DateTime createdAt;

  double get progress => (totalChunks == null || totalChunks == 0)
      ? 0
      : uploadedChunkIndexes.length / totalChunks!;

  AudioUpload copyWith({
    AudioUploadStatus? status,
    String? serverAudioFileId,
    int? totalChunks,
    List<int>? uploadedChunkIndexes,
  }) {
    return AudioUpload(
      localId: localId,
      meetingId: meetingId,
      filePath: filePath,
      durationSeconds: durationSeconds,
      status: status ?? this.status,
      serverAudioFileId: serverAudioFileId ?? this.serverAudioFileId,
      totalChunks: totalChunks ?? this.totalChunks,
      uploadedChunkIndexes: uploadedChunkIndexes ?? this.uploadedChunkIndexes,
      chunkSizeBytes: chunkSizeBytes,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        localId,
        meetingId,
        filePath,
        durationSeconds,
        status,
        serverAudioFileId,
        totalChunks,
        uploadedChunkIndexes,
        chunkSizeBytes,
        createdAt,
      ];
}
