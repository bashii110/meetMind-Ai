import '../../domain/entities/calendar_event.dart';

class CalendarEventModel extends CalendarEvent {
  const CalendarEventModel({
    required super.type,
    required super.id,
    required super.title,
    required super.dateTime,
    required super.allDay,
    super.status,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      type: json['type'] == 'meeting' ? CalendarEventType.meeting : CalendarEventType.taskDeadline,
      id: json['id'].toString(),
      title: json['title'] as String,
      dateTime: DateTime.parse(json['datetime'] as String),
      allDay: json['all_day'] as bool? ?? false,
      status: json['status'] as String?,
    );
  }
}
