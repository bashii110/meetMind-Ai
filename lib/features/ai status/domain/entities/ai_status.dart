/// Mirrors `App\Enums\AudioFileStatus` on the backend, plus the
/// controller's synthetic `no_recording` value for a meeting with no
/// audio file at all yet. See MeetingAiController::aiStatus.
enum AiPipelineStatus {
  noRecording,
  pending,
  uploading,
  uploaded,
  transcribing,
  transcribed,
  summarizing,
  summarized,
  failed,
}

class AiStatus {
  const AiStatus({required this.status, this.errorMessage});

  final AiPipelineStatus status;
  final String? errorMessage;

  bool get hasRecording => status != AiPipelineStatus.noRecording;

  bool get isProcessing =>
      status == AiPipelineStatus.uploading ||
      status == AiPipelineStatus.transcribing ||
      status == AiPipelineStatus.summarizing;

  bool get isReady => status == AiPipelineStatus.summarized;

  bool get hasFailed => status == AiPipelineStatus.failed;

  String get label => switch (status) {
        AiPipelineStatus.noRecording => 'No recording yet',
        AiPipelineStatus.pending => 'Waiting to upload',
        AiPipelineStatus.uploading => 'Uploading recording…',
        AiPipelineStatus.uploaded => 'Queued for transcription',
        AiPipelineStatus.transcribing => 'Transcribing…',
        AiPipelineStatus.transcribed => 'Queued for summarization',
        AiPipelineStatus.summarizing => 'Generating summary…',
        AiPipelineStatus.summarized => 'Ready',
        AiPipelineStatus.failed => 'Processing failed',
      };
}
