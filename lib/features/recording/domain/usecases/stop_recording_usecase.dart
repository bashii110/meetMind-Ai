import 'dart:async';

import 'package:meetmind_ai/features/recording/domain/entities/pending_upload.dart';
import 'package:meetmind_ai/features/recording/domain/repositories/audio_upload_repository.dart';
import 'package:meetmind_ai/features/recording/domain/repositories/recording_repository.dart';


class StopRecordingUseCase {
  const StopRecordingUseCase({
    required RecordingRepository recordingRepository,
    required AudioUploadRepository uploadRepository,
  })  : _recordingRepository = recordingRepository,
        _uploadRepository = uploadRepository;

  final RecordingRepository _recordingRepository;
  final AudioUploadRepository _uploadRepository;

  /// Stops the mic, saves the recording to the local upload queue, and
  /// returns immediately — DESIGN.md 3.5: "Subtle 'processing in
  /// background' indicator once stopped, so users can navigate away
  /// without losing progress." The actual chunked upload keeps running
  /// after this returns; if it fails, the entry's `status`/`errorMessage`
  /// records that for the meeting details screen to surface, and
  /// `resumeAll()` will retry it on next app start regardless.
  Future<PendingUpload> call({required String meetingId}) async {
    final audio = await _recordingRepository.stop();
    final pending = await _uploadRepository.enqueue(meetingId: meetingId, audio: audio);
    unawaited(_uploadRepository.upload(pending.id));
    return pending;
  }
}
