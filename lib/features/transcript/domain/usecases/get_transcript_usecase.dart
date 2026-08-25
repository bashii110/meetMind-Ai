

import 'package:meetmind_ai/features/ai_summary/domain/repositories/ai_summary_repository.dart';
import 'package:meetmind_ai/features/transcript/domain/entities/transcript.dart';

class GetTranscriptUseCase {
  const GetTranscriptUseCase(this._repository);

  final AiSummaryRepository _repository;

  Future<Transcript?> call(String meetingId) => _repository.getTranscript(meetingId);
}
