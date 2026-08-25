import 'package:meetmind_ai/features/ai_summary/domain/repositories/ai_summary_repository.dart';
import 'package:meetmind_ai/features/tasks/domain/entities/task_candidate.dart';

class ListTaskCandidatesUseCase {
  const ListTaskCandidatesUseCase(this._repository);

  final AiSummaryRepository _repository;

  Future<List<TaskCandidate>> call(String meetingId) => _repository.getTaskCandidates(meetingId);
}
