

import 'package:meetmind_ai/features/ai_summary/domain/repositories/ai_summary_repository.dart';

class ConfirmTaskCandidateUseCase {
  const ConfirmTaskCandidateUseCase(this._repository);

  final AiSummaryRepository _repository;

  Future<void> call(
    String taskCandidateId, {
    String? title,
    String? description,
    String? priority,
    DateTime? deadline,
    String? assignedUserId,
  }) {
    return _repository.confirmTaskCandidate(
      taskCandidateId,
      title: title,
      description: description,
      priority: priority,
      deadline: deadline,
      assignedUserId: assignedUserId,
    );
  }
}
