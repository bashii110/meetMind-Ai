import 'package:equatable/equatable.dart';

/// Where a locally-recorded file is in the chunked-upload pipeline.
/// Mirrors (a simplified, client-side view of) `App\Enums\AudioFileStatus`
/// on the backend, but tracked independently here since this entity exists
/// *before* the server even knows about the recording (queued/uploading),
/// per ARCHITECTURE.md 2.4's `pending_upload -> uploaded -> processing`
/// local status flow.
enum PendingUploadStatus { queued, uploading, uploaded, failed }

/// A locally-recorded audio file queued for (or in the middle of) chunked
/// upload to the backend. Persisted via Hive (see
/// `PendingUploadLocalDataSource`) — the whole point of this entity is
/// that it survives the app being closed or killed mid-upload, so
/// `AudioUploadRepository.resumeAll()` can pick it back up on next launch
/// (ARCHITECTURE.md 2.3's offline/resilience strategy, applied to
/// recordings specifically).
class PendingUpload extends Equatable {
  const PendingUpload({
    required this.id,
    required this.meetingId,
    required this.filePath,
    required this.extension,
    required this.totalChunks,
    required this.fileSizeBytes,
    required this.durationSeconds,
    required this.createdAt,
    this.remoteAudioFileId,
    this.uploadedChunks = const [],
    this.status = PendingUploadStatus.queued,
    this.errorMessage,
  });

  /// Local id (a uuid) — not the backend AudioFile id, which doesn't exist
  /// until the upload's `init` step completes (see [remoteAudioFileId]).
  final String id;
  final String meetingId;
  final String filePath;
  final String extension;
  final int totalChunks;
  final int fileSizeBytes;
  final int durationSeconds;
  final DateTime createdAt;

  /// Set once `POST /meetings/{id}/recording/init` succeeds. Null means
  /// upload hasn't started yet, or was interrupted before init finished.
  final String? remoteAudioFileId;

  /// Chunk indexes confirmed uploaded, purely for local progress display —
  /// the authoritative source of truth is always re-fetched from the
  /// server's `received_chunks` before resuming (see
  /// `AudioUploadRepositoryImpl.upload`), so this can't drift into a state
  /// where we skip a chunk the server never actually received.
  final List<int> uploadedChunks;

  final PendingUploadStatus status;
  final String? errorMessage;

  double get progress => totalChunks == 0 ? 0 : uploadedChunks.length / totalChunks;

  PendingUpload copyWith({
    String? remoteAudioFileId,
    List<int>? uploadedChunks,
    PendingUploadStatus? status,
    String? errorMessage,
  }) {
    return PendingUpload(
      id: id,
      meetingId: meetingId,
      filePath: filePath,
      extension: extension,
      totalChunks: totalChunks,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
      remoteAudioFileId: remoteAudioFileId ?? this.remoteAudioFileId,
      uploadedChunks: uploadedChunks ?? this.uploadedChunks,
      status: status ?? this.status,
      // Deliberately not `?? this.errorMessage` — callers pass null to
      // explicitly clear a previous failure when a retry starts.
      errorMessage: errorMessage,
    );
  }

  /// Hive stores plain Maps/Lists/primitives natively (no generated
  /// TypeAdapter needed), matching this project's existing convention of
  /// hand-written `toJson`/`fromJson` everywhere else instead of codegen.
  Map<String, dynamic> toJson() => {
        'id': id,
        'meeting_id': meetingId,
        'file_path': filePath,
        'extension': extension,
        'total_chunks': totalChunks,
        'file_size_bytes': fileSizeBytes,
        'duration_seconds': durationSeconds,
        'created_at': createdAt.millisecondsSinceEpoch,
        'remote_audio_file_id': remoteAudioFileId,
        'uploaded_chunks': uploadedChunks,
        'status': status.name,
        'error_message': errorMessage,
      };

  factory PendingUpload.fromJson(Map<String, dynamic> json) {
    return PendingUpload(
      id: json['id'] as String,
      meetingId: json['meeting_id'] as String,
      filePath: json['file_path'] as String,
      extension: json['extension'] as String,
      totalChunks: json['total_chunks'] as int,
      fileSizeBytes: json['file_size_bytes'] as int,
      durationSeconds: json['duration_seconds'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      remoteAudioFileId: json['remote_audio_file_id'] as String?,
      uploadedChunks: ((json['uploaded_chunks'] as List?) ?? const [])
          .map((e) => e as int)
          .toList(),
      status: PendingUploadStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PendingUploadStatus.queued,
      ),
      errorMessage: json['error_message'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        meetingId,
        filePath,
        extension,
        totalChunks,
        fileSizeBytes,
        durationSeconds,
        createdAt,
        remoteAudioFileId,
        uploadedChunks,
        status,
        errorMessage,
      ];
}
