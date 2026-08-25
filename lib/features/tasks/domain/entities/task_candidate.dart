import 'package:equatable/equatable.dart';

/** FR-6.3. Mirrors `App\Enums\TaskCandidateStatus`. */
enum TaskCandidateStatus { pending, confirmed, dismissed }

/// An AI-extracted action item awaiting human confirmation before it
/// becomes a real Task — SRD FR-6.3: "Users shall review and confirm/edit
/// AI-extracted tasks before they are created."
class TaskCandidate extends Equatable {
  const TaskCandidate({
    required this.id,
    required this.meetingId,
    required this.title,
    required this.suggestedPriority,
    required this.status,
    this.description,
    this.suggestedAssigneeName,
    this.suggestedAssigneeUserId,
    this.suggestedDeadline,
  });

  final String id;
  final String meetingId;
  final String title;
  final String? description;

  /// Display name for the suggested assignee — the matched workspace
  /// member's name if the AI's free-text guess matched one, else the raw
  /// name it extracted from the transcript. Either way, just a suggestion
  /// for the reviewer; confirming can override it.
  final String? suggestedAssigneeName;
  final String? suggestedAssigneeUserId;
  final DateTime? suggestedDeadline;
  final String suggestedPriority;
  final TaskCandidateStatus status;

  @override
  List<Object?> get props => [
        id,
        meetingId,
        title,
        description,
        suggestedAssigneeName,
        suggestedAssigneeUserId,
        suggestedDeadline,
        suggestedPriority,
        status,
      ];
}
