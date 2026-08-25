

import 'package:meetmind_ai/features/ai_summary/domain/repositories/ai_summary_repository.dart';

class DismissTaskCandidateUseCase {
  const DismissTaskCandidateUseCase(this._repository);

  final AiSummaryRepository _repository;

  Future<void> call(String taskCandidateId) => _repository.dismissTaskCandidate(taskCandidateId);
}
