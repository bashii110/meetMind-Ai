

import 'package:meetmind_ai/features/tasks/domain/entities/task_candidate.dart';

class TaskCandidateModel extends TaskCandidate {
  const TaskCandidateModel({
    required super.id,
    required super.meetingId,
    required super.title,
    required super.suggestedPriority,
    required super.status,
    super.description,
    super.suggestedAssigneeName,
    super.suggestedAssigneeUserId,
    super.suggestedDeadline,
  });

  factory TaskCandidateModel.fromJson(Map<String, dynamic> json) {
    final assignee = json['suggested_assignee'] as Map<String, dynamic>?;

    return TaskCandidateModel(
      id: json['id'].toString(),
      meetingId: json['meeting_id'].toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      suggestedAssigneeName: assignee?['name'] as String? ?? json['suggested_assignee_name'] as String?,
      suggestedAssigneeUserId: assignee?['id']?.toString(),
      suggestedDeadline: json['suggested_deadline'] != null
          ? DateTime.tryParse(json['suggested_deadline'] as String)
          : null,
      suggestedPriority: json['suggested_priority'] as String? ?? 'medium',
      status: _parseStatus(json['status'] as String?),
    );
  }

  static TaskCandidateStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'confirmed':
        return TaskCandidateStatus.confirmed;
      case 'dismissed':
        return TaskCandidateStatus.dismissed;
      case 'pending':
      default:
        return TaskCandidateStatus.pending;
    }
  }
}
