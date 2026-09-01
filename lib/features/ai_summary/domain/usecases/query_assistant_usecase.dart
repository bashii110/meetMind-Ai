import '../repositories/ai_summary_repository.dart';

class QueryAssistantUseCase {
  const QueryAssistantUseCase(this._repository);

  final AiSummaryRepository _repository;

  /// SRD FR-11.1. [prompt] is free-form natural language — the backend
  /// contextualizes it with the meeting's transcript (and tasks, for
  /// ownership/deadline questions) before calling OpenAI.
  Future<String> call(String meetingId, String prompt) => _repository.queryAssistant(meetingId, prompt);
}
