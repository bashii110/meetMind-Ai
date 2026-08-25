import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/transcript/domain/entities/transcript.dart';
import '../../../ai_summary/presentation/providers/ai_summary_providers.dart';

/// autoDispose — cheap to refetch, no reason to keep cached once the
/// Transcript tab isn't visible. Returns null while the transcript hasn't
/// been generated yet (see AiSummaryRepository.getTranscript); the
/// Transcript tab only watches this once ai-status says it should exist.
final transcriptProvider = FutureProvider.autoDispose.family<Transcript?, String>((ref, meetingId) {
  return ref.watch(getTranscriptUseCaseProvider)(meetingId);
});
