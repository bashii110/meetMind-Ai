import 'package:dio/dio.dart';

import '../models/calendar_event_model.dart';

class CalendarRemoteDataSource {
  const CalendarRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<CalendarEventModel>> events(DateTime start, DateTime end) async {
    final response = await _dio.get('/calendar', queryParameters: {
      'start': _formatDate(start),
      'end': _formatDate(end),
    });

    final items = (response.data['data'] as List?) ?? const [];
    return items.map((e) => CalendarEventModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
