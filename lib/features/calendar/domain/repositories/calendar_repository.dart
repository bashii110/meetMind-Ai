import '../entities/calendar_event.dart';

abstract interface class CalendarRepository {
  /// [start] and [end] are inclusive; both are sent as plain dates
  /// (`YYYY-MM-DD`) to GET /calendar — see CalendarController::index.
  Future<List<CalendarEvent>> events({required DateTime start, required DateTime end});
}
