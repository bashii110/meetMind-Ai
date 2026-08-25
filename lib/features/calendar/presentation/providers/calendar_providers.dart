import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/calendar_remote_data_source.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/usecases/get_calendar_events_usecase.dart';

final calendarRemoteDataSourceProvider = Provider(
  (ref) => CalendarRemoteDataSource(ref.watch(dioProvider)),
);

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepositoryImpl(ref.watch(calendarRemoteDataSourceProvider)),
);

final getCalendarEventsUseCaseProvider =
    Provider((ref) => GetCalendarEventsUseCase(ref.watch(calendarRepositoryProvider)));
