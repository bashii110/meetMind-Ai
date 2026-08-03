import '../entities/meeting_filters.dart';
import '../entities/paginated_meetings.dart';
import '../repositories/meeting_repository.dart';

class ListMeetingsUseCase {
  const ListMeetingsUseCase(this._repository);

  final MeetingRepository _repository;

  Future<PaginatedMeetings> call({MeetingFilters filters = MeetingFilters.empty, int page = 1}) {
    return _repository.list(filters: filters, page: page);
  }
}
