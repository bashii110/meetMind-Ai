import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_remote_data_source.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  const CalendarRepositoryImpl(this._remote);

  final CalendarRemoteDataSource _remote;

  @override
  Future<List<CalendarEvent>> events({required DateTime start, required DateTime end}) {
    return _remote.events(start, end);
  }
}
