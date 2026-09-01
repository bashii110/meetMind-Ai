
import 'package:meetmind_ai/features/ai%20status/domain/entities/ai_status.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/meeting_summary.dart';
import 'package:meetmind_ai/features/tasks/domain/entities/task_candidate.dart';
import 'package:meetmind_ai/features/transcript/domain/entities/transcript.dart';

abstract interface class AiSummaryRepository {
  Future<AiStatus> getStatus(String meetingId);

  /// Null means "not generated yet" — a normal, expected state while the
  /// pipeline is still running, not an error (the backend returns 404 for
  /// this, which the implementation translates to null rather than
  /// throwing).
  Future<Transcript?> getTranscript(String meetingId);

  /// Null means "not generated yet" — see [getTranscript].
  Future<MeetingSummary?> getSummary(String meetingId);

  Future<List<TaskCandidate>> getTaskCandidates(String meetingId);

  /// Confirms an AI-suggested task, optionally overriding any of its
  /// suggested fields first (FR-6.3). Fields left null keep the AI's
  /// suggestion.
  Future<void> confirmTaskCandidate(
    String taskCandidateId, {
    String? title,
    String? description,
    String? priority,
    DateTime? deadline,
    String? assignedUserId,
  });

  Future<void> dismissTaskCandidate(String taskCandidateId);

  /// SRD FR-11.1/11.2 — sends a natural-language [prompt] to the AI
  /// assistant. The backend contextualizes it with this meeting's
  /// transcript (and tasks, for prompts like "who owns Task 3?") before
  /// calling OpenAI, per ARCHITECTURE.md's documented
  /// `POST /meetings/{id}/assistant/query` endpoint. One generic prompt
  /// endpoint covers every assistant capability the SRD lists (summarize,
  /// draft a follow-up email, generate minutes, convert to a project
  /// plan...) — the frontend just supplies different preset prompt text
  /// for each (see AssistantTab's suggested prompts).
  Future<String> queryAssistant(String meetingId, String prompt);
}
