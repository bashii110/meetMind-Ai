import 'package:meetmind_ai/features/meetings/domain/entities/meeting.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/meeting_filters.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/paginated_meetings.dart';
import 'package:meetmind_ai/features/meetings/domain/repositories/meeting_repository.dart';

/// Hand-written fake — mirrors FakeTaskRepository's shape. `list()`
/// returns everything in [items] as a single page; controller tests only
/// need to observe that a fetch happened and with which filters.
class FakeMeetingRepository implements MeetingRepository {
  FakeMeetingRepository({List<Meeting> items = const []}) : items = List.of(items);

  List<Meeting> items;
  MeetingFilters? lastFilters;

  @override
  Future<PaginatedMeetings> list({MeetingFilters filters = MeetingFilters.empty, int page = 1}) async {
    lastFilters = filters;
    return PaginatedMeetings(items: items, currentPage: 1, lastPage: 1, total: items.length);
  }

  @override
  Future<Meeting> getById(String id) async => items.firstWhere((m) => m.id == id);

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
  }) async =>
      throw UnimplementedError();

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
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) async {}

  @override
  Future<Meeting> changeStatus(String id, String status) async => items.firstWhere((m) => m.id == id);

  @override
  Future<List<String>> inviteParticipants(String meetingId, List<String> emails) async => [];

  @override
  Future<void> removeParticipant(String meetingId, String userId) async {}

  @override
  Future<void> respondToInvitation(String meetingId, String status) async {}
}
