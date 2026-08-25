import 'package:dio/dio.dart';

import '../models/audio_file_model.dart';
import 'package:meetmind_ai/features/recording/data/models/upload_progress_model.dart';

/// Talks to the chunked/resumable audio upload endpoints — see
/// backend/app/Http/Controllers/Api/V1/AudioFileController.php and
/// backend/app/Services/AudioUploadService.php. The chunking/resume
/// protocol itself lives in [AudioUploadRepositoryImpl]; this class is
/// just the four HTTP calls.
class AudioUploadRemoteDataSource {
  const AudioUploadRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AudioFileModel> init({
    required String meetingId,
    required int totalChunks,
    required String extension,
    String? mimeType,
    int? totalSize,
    int? durationSeconds,
  }) async {
    final response = await _dio.post('/meetings/$meetingId/recording/init', data: {
      'total_chunks': totalChunks,
      'extension': extension,
      if (mimeType != null) 'mime_type': mimeType,
      if (totalSize != null) 'total_size': totalSize,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });
    return AudioFileModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> uploadChunk({
    required String audioFileId,
    required int chunkIndex,
    required List<int> bytes,
  }) async {
    final form = FormData.fromMap({
      'chunk_index': chunkIndex,
      'chunk': MultipartFile.fromBytes(
        bytes,
        filename: 'chunk_$chunkIndex',
      ),
    });

    await _dio.post(
      '/audio-files/$audioFileId/chunks',
      data: form,
    );
  }

  Future<UploadProgressModel> status(String audioFileId) async {
    final response = await _dio.get('/audio-files/$audioFileId/status');
    return UploadProgressModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AudioFileModel> complete(String audioFileId) async {
    final response = await _dio.post('/audio-files/$audioFileId/complete');
    return AudioFileModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
