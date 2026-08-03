import '../entities/meeting.dart';
import '../entities/meeting_filters.dart';
import '../entities/paginated_meetings.dart';

abstract interface class MeetingRepository {
  Future<PaginatedMeetings> list({MeetingFilters filters = MeetingFilters.empty, int page = 1});

  Future<Meeting> getById(String id);

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
  });

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
  });

  Future<void> delete(String id);

  Future<Meeting> changeStatus(String id, String status);

  /// @return list of emails that don't correspond to a registered user
  Future<List<String>> inviteParticipants(String meetingId, List<String> emails);

  Future<void> removeParticipant(String meetingId, String userId);

  Future<void> respondToInvitation(String meetingId, String status);
}
