import 'package:meetmind_ai/features/ai_summary/domain/repositories/ai_summary_repository.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/meeting_summary.dart';


class GetMeetingSummaryUseCase {
  const GetMeetingSummaryUseCase(this._repository);

  final AiSummaryRepository _repository;

  Future<MeetingSummary?> call(String meetingId) => _repository.getSummary(meetingId);
}
