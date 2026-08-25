import 'package:equatable/equatable.dart';

/// DESIGN.md 3.8: "Color-coded dots for meetings vs. task deadlines."
enum CalendarEventType { meeting, taskDeadline }

/// Mirrors backend/app/Http/Resources/CalendarEventResource.php. A meeting
/// and a task deadline are different backend models, unified into one
/// shape here so the calendar screen can render both from a single feed
/// without knowing which underlying resource each item came from.
class CalendarEvent extends Equatable {
  const CalendarEvent({
    required this.type,
    required this.id,
    required this.title,
    required this.dateTime,
    required this.allDay,
    this.status,
  });

  final CalendarEventType type;
  final String id;
  final String title;
  final DateTime dateTime;
  final bool allDay;
  final String? status;

  @override
  List<Object?> get props => [type, id, title, dateTime, allDay, status];
}
