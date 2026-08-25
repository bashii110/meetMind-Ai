import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/calendar_event.dart';
import 'calendar_providers.dart';

/// DESIGN.md 3.8: "Month/Week/Day toggle at top."
enum CalendarViewMode { month, week, day }

class CalendarState {
  const CalendarState({required this.focusedDay, required this.viewMode, required this.events});

  /// The month/week being shown, or the single day in [CalendarViewMode.day].
  final DateTime focusedDay;
  final CalendarViewMode viewMode;

  /// Every event within the currently visible range (already scoped by the
  /// backend to the range this state was fetched for).
  final List<CalendarEvent> events;

  List<CalendarEvent> eventsOn(DateTime day) {
    return events.where((e) => _isSameDay(e.dateTime, day)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Fetches whatever range the current [CalendarViewMode] implies around
/// [CalendarState.focusedDay], re-fetching whenever the person moves to a
/// different month/week/day or switches view mode.
class CalendarController extends AsyncNotifier<CalendarState> {
  @override
  Future<CalendarState> build() => _load(DateTime.now(), CalendarViewMode.month);

  Future<CalendarState> _load(DateTime focusedDay, CalendarViewMode mode) async {
    final range = _rangeFor(focusedDay, mode);
    final events = await ref.read(getCalendarEventsUseCaseProvider)(start: range.start, end: range.end);
    return CalendarState(focusedDay: focusedDay, viewMode: mode, events: events);
  }

  ({DateTime start, DateTime end}) _rangeFor(DateTime day, CalendarViewMode mode) {
    switch (mode) {
      case CalendarViewMode.month:
        final first = DateTime(day.year, day.month, 1);
        final last = DateTime(day.year, day.month + 1, 0);
        return (start: first, end: last);
      case CalendarViewMode.week:
        // ISO-ish week starting Sunday, matching DateFormat's default
        // first-day-of-week convention used elsewhere in this app.
        final start = day.subtract(Duration(days: day.weekday % 7));
        return (start: start, end: start.add(const Duration(days: 6)));
      case CalendarViewMode.day:
        final start = DateTime(day.year, day.month, day.day);
        return (start: start, end: start);
    }
  }

  Future<void> setViewMode(CalendarViewMode mode) async {
    final day = state.valueOrNull?.focusedDay ?? DateTime.now();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(day, mode));
  }

  Future<void> goTo(DateTime day) async {
    final mode = state.valueOrNull?.viewMode ?? CalendarViewMode.month;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(day, mode));
  }

  Future<void> next() => goTo(_shift(1));

  Future<void> previous() => goTo(_shift(-1));

  Future<void> today() => goTo(DateTime.now());

  DateTime _shift(int direction) {
    final current = state.valueOrNull;
    final day = current?.focusedDay ?? DateTime.now();
    switch (current?.viewMode ?? CalendarViewMode.month) {
      case CalendarViewMode.month:
        return DateTime(day.year, day.month + direction, 1);
      case CalendarViewMode.week:
        return day.add(Duration(days: 7 * direction));
      case CalendarViewMode.day:
        return day.add(Duration(days: direction));
    }
  }
}

final calendarControllerProvider = AsyncNotifierProvider<CalendarController, CalendarState>(CalendarController.new);
