import 'dart:convert';

import '../../domain/entities/audio_upload.dart';

class AudioUploadModel extends AudioUpload {
  const AudioUploadModel({
    required super.localId,
    required super.meetingId,
    required super.filePath,
    required super.durationSeconds,
    required super.status,
    super.serverAudioFileId,
    super.totalChunks,
    super.uploadedChunkIndexes,
    super.chunkSizeBytes,
    required super.createdAt,
  });

  factory AudioUploadModel.fromEntity(AudioUpload e) => AudioUploadModel(
        localId: e.localId,
        meetingId: e.meetingId,
        filePath: e.filePath,
        durationSeconds: e.durationSeconds,
        status: e.status,
        serverAudioFileId: e.serverAudioFileId,
        totalChunks: e.totalChunks,
        uploadedChunkIndexes: e.uploadedChunkIndexes,
        chunkSizeBytes: e.chunkSizeBytes,
        createdAt: e.createdAt,
      );

  factory AudioUploadModel.fromJson(Map<String, dynamic> json) {
    return AudioUploadModel(
      localId: json['local_id'] as String,
      meetingId: json['meeting_id'] as String,
      filePath: json['file_path'] as String,
      durationSeconds: json['duration_seconds'] as int,
      status: AudioUploadStatus.values.byName(json['status'] as String),
      serverAudioFileId: json['server_audio_file_id'] as String?,
      totalChunks: json['total_chunks'] as int?,
      uploadedChunkIndexes: (json['uploaded_chunk_indexes'] as List? ?? const [])
          .map((e) => e as int)
          .toList(),
      chunkSizeBytes: json['chunk_size_bytes'] as int? ?? 512 * 1024,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'local_id': localId,
        'meeting_id': meetingId,
        'file_path': filePath,
        'duration_seconds': durationSeconds,
        'status': status.name,
        'server_audio_file_id': serverAudioFileId,
        'total_chunks': totalChunks,
        'uploaded_chunk_indexes': uploadedChunkIndexes,
        'chunk_size_bytes': chunkSizeBytes,
        'created_at': createdAt.toIso8601String(),
      };

  static AudioUploadModel decode(String raw) => AudioUploadModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  String encode() => jsonEncode(toJson());
}
