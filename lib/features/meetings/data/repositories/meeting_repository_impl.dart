import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_filters.dart';
import '../../domain/entities/paginated_meetings.dart';
import '../../domain/repositories/meeting_repository.dart';
import '../datasources/meeting_remote_data_source.dart';

class MeetingRepositoryImpl implements MeetingRepository {
  const MeetingRepositoryImpl(this._remote);

  final MeetingRemoteDataSource _remote;

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Future<PaginatedMeetings> list({MeetingFilters filters = MeetingFilters.empty, int page = 1}) {
    return _remote.list(filters.toQueryParameters(), page);
  }

  @override
  Future<Meeting> getById(String id) => _remote.getById(id);

  @override
  Future<Meeting> create({
    required String title,
    String? description,
    required DateTime date,
    String? time,
    String? location,
    String? onlineLink,
    String priority = 'medium',
    String? category,
    List<String> tags = const [],
    List<String> participantEmails = const [],
    String? workspaceId,
  }) {
    return _remote.create({
      if (workspaceId != null) 'workspace_id': int.tryParse(workspaceId) ?? workspaceId,
      'title': title,
      if (description != null) 'description': description,
      'date': _formatDate(date),
      if (time != null) 'time': time,
      if (location != null) 'location': location,
      if (onlineLink != null) 'online_link': onlineLink,
      'priority': priority,
      if (category != null) 'category': category,
      if (tags.isNotEmpty) 'tags': tags,
      if (participantEmails.isNotEmpty) 'participant_emails': participantEmails,
    });
  }

  @override
  Future<Meeting> update(
    String id, {
    String? title,
    String? description,
    DateTime? date,
    String? time,
    String? location,
    String? onlineLink,
    String? priority,
    String? category,
    List<String>? tags,
  }) {
    return _remote.update(id, {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (date != null) 'date': _formatDate(date),
      if (time != null) 'time': time,
      if (location != null) 'location': location,
      if (onlineLink != null) 'online_link': onlineLink,
      if (priority != null) 'priority': priority,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
    });
  }

  @override
  Future<void> delete(String id) => _remote.delete(id);

  @override
  Future<Meeting> changeStatus(String id, String status) => _remote.changeStatus(id, status);

  @override
  Future<List<String>> inviteParticipants(String meetingId, List<String> emails) {
    return _remote.inviteParticipants(meetingId, emails);
  }

  @override
  Future<void> removeParticipant(String meetingId, String userId) {
    return _remote.removeParticipant(meetingId, userId);
  }

  @override
  Future<void> respondToInvitation(String meetingId, String status) {
    return _remote.respondToInvitation(meetingId, status);
  }
}
