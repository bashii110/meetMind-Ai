/// Mirrors TaskRepository::forUser's $filters shape on the backend.
/// DESIGN.md 3.7: Kanban columns encode status, so [status] is mainly used
/// by the mobile grouped-list view's filter chips rather than the board.
class TaskFilters {
  const TaskFilters({
    this.status,
    this.priority,
    this.meetingId,
    this.assignedToMe = false,
    this.search,
  });

  final String? status;
  final String? priority;
  final String? meetingId;
  final bool assignedToMe;
  final String? search;

  static const empty = TaskFilters();

  Map<String, dynamic> toQueryParameters() => {
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (meetingId != null) 'meeting_id': meetingId,
        if (assignedToMe) 'assigned_to_me': true,
        if (search != null && search!.isNotEmpty) 'search': search,
      };

  TaskFilters copyWith({
    String? status,
    bool clearStatus = false,
    String? priority,
    bool clearPriority = false,
    String? meetingId,
    bool clearMeetingId = false,
    bool? assignedToMe,
    String? search,
    bool clearSearch = false,
  }) {
    return TaskFilters(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      meetingId: clearMeetingId ? null : (meetingId ?? this.meetingId),
      assignedToMe: assignedToMe ?? this.assignedToMe,
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}
