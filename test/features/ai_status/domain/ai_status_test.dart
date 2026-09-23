import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/features/ai%20status/domain/entities/ai_status.dart';

void main() {
  test('hasRecording is false only for noRecording', () {
    expect(const AiStatus(status: AiPipelineStatus.noRecording).hasRecording, isFalse);
    expect(const AiStatus(status: AiPipelineStatus.pending).hasRecording, isTrue);
  });

  test('isProcessing covers only uploading/transcribing/summarizing', () {
    const processing = [
      AiPipelineStatus.uploading,
      AiPipelineStatus.transcribing,
      AiPipelineStatus.summarizing,
    ];
    for (final status in processing) {
      expect(AiStatus(status: status).isProcessing, isTrue, reason: status.name);
    }
    for (final status in AiPipelineStatus.values.where((s) => !processing.contains(s))) {
      expect(AiStatus(status: status).isProcessing, isFalse, reason: status.name);
    }
  });

  test('isReady is true only for summarized; hasFailed only for failed', () {
    expect(const AiStatus(status: AiPipelineStatus.summarized).isReady, isTrue);
    expect(const AiStatus(status: AiPipelineStatus.transcribed).isReady, isFalse);
    expect(const AiStatus(status: AiPipelineStatus.failed).hasFailed, isTrue);
    expect(const AiStatus(status: AiPipelineStatus.summarized).hasFailed, isFalse);
  });

  test('every pipeline status has a distinct, human-readable label', () {
    final labels = AiPipelineStatus.values.map((s) => AiStatus(status: s).label).toSet();
    expect(labels.length, AiPipelineStatus.values.length);
  });
}
