import '../entities/calendar_event.dart';
import '../repositories/calendar_repository.dart';

class GetCalendarEventsUseCase {
  const GetCalendarEventsUseCase(this._repository);

  final CalendarRepository _repository;

  Future<List<CalendarEvent>> call({required DateTime start, required DateTime end}) {
    return _repository.events(start: start, end: end);
  }
}
