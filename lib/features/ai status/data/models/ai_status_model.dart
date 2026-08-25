

import 'package:meetmind_ai/features/ai%20status/domain/entities/ai_status.dart';

class AiStatusModel extends AiStatus {
  const AiStatusModel({required super.status, super.errorMessage});

  factory AiStatusModel.fromJson(Map<String, dynamic> json) {
    return AiStatusModel(
      status: _parseStatus(json['status'] as String?),
      errorMessage: json['error_message'] as String?,
    );
  }

  static AiPipelineStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'pending':
        return AiPipelineStatus.pending;
      case 'uploading':
        return AiPipelineStatus.uploading;
      case 'uploaded':
        return AiPipelineStatus.uploaded;
      case 'transcribing':
        return AiPipelineStatus.transcribing;
      case 'transcribed':
        return AiPipelineStatus.transcribed;
      case 'summarizing':
        return AiPipelineStatus.summarizing;
      case 'summarized':
        return AiPipelineStatus.summarized;
      case 'failed':
        return AiPipelineStatus.failed;
      case 'no_recording':
      default:
        return AiPipelineStatus.noRecording;
    }
  }
}
