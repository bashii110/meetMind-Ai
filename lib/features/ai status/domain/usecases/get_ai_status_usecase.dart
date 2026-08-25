

import 'package:meetmind_ai/features/ai%20status/domain/entities/ai_status.dart';
import 'package:meetmind_ai/features/ai_summary/domain/repositories/ai_summary_repository.dart';

class GetAiStatusUseCase {
  const GetAiStatusUseCase(this._repository);

  final AiSummaryRepository _repository;

  Future<AiStatus> call(String meetingId) => _repository.getStatus(meetingId);
}
