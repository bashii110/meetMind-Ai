import 'package:dio/dio.dart';

import '../models/calendar_event_model.dart';

class CalendarRemoteDataSource {
  const CalendarRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<CalendarEventModel>> events(
      DateTime start,
      DateTime end,
      ) async {
    final response = await _dio.get(
      '/calendar',
      queryParameters: {
        'start': _formatDate(start),
        'end': _formatDate(end),
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;

    final meetings = (data['meetings'] as List?) ?? const [];
    final taskDeadlines = (data['task_deadlines'] as List?) ?? const [];

    final events = <CalendarEventModel>[];

    // Convert meetings to the common CalendarEvent format.
    for (final item in meetings) {
      final meeting = item as Map<String, dynamic>;

      final date = meeting['date'] as String;
      final time = meeting['time'] as String;

      events.add(
        CalendarEventModel.fromJson({
          'type': 'meeting',
          'id': meeting['id'],
          'title': meeting['title'],
          'datetime': '${date}T$time',
          'all_day': false,
          'status': meeting['status'],
        }),
      );
    }

    // Convert task deadlines to the common CalendarEvent format.
    for (final item in taskDeadlines) {
      final task = item as Map<String, dynamic>;

      events.add(
        CalendarEventModel.fromJson({
          'type': 'taskDeadline',
          'id': task['id'],
          'title': task['title'],
          'datetime': task['deadline'],
          'all_day': true,
          'status': task['status'],
        }),
      );
    }

    // Keep calendar events chronologically sorted.
    events.sort(
          (a, b) => a.dateTime.compareTo(b.dateTime),
    );

    return events;
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
}