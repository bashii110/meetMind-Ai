import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/calendar_event.dart';
import '../providers/calendar_controller.dart';
import '../widgets/day_agenda.dart';

/// DESIGN.md 3.8: "Month/Week/Day toggle at top. Color-coded dots for
/// meetings vs. task deadlines. Tapping a day reveals a bottom sheet with
/// that day's agenda."
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  String _periodLabel(CalendarState s) {
    switch (s.viewMode) {
      case CalendarViewMode.month:
        return DateFormat.yMMMM().format(s.focusedDay);
      case CalendarViewMode.week:
        final start = s.focusedDay.subtract(Duration(days: s.focusedDay.weekday % 7));
        final end = start.add(const Duration(days: 6));
        return '${DateFormat.MMMd().format(start)} – ${DateFormat.MMMd().format(end)}';
      case CalendarViewMode.day:
        return DateFormat.yMMMEd().format(s.focusedDay);
    }
  }

  void _showDayAgenda(BuildContext context, DateTime day, List<CalendarEvent> events) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: DayAgenda(day: day, events: events)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarControllerProvider);
    final controller = ref.read(calendarControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          debugPrint('CALENDAR ERROR: $error');
          debugPrint('CALENDAR STACK: $stack');

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error is ApiFailure
                    ? '${error.statusCode}: ${error.message}'
                    : 'Calendar error: $error',
              ),
            ),
          );
        },
        data: (calendarState) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: SegmentedButton<CalendarViewMode>(
                segments: const [
                  ButtonSegment(value: CalendarViewMode.month, label: Text('Month')),
                  ButtonSegment(value: CalendarViewMode.week, label: Text('Week')),
                  ButtonSegment(value: CalendarViewMode.day, label: Text('Day')),
                ],
                selected: {calendarState.viewMode},
                onSelectionChanged: (selection) => controller.setViewMode(selection.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: controller.previous),
                  TextButton(
                    onPressed: controller.today,
                    child: Text(_periodLabel(calendarState), style: Theme.of(context).textTheme.titleMedium),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: controller.next),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Expanded(
              child: switch (calendarState.viewMode) {
                CalendarViewMode.month => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    child: _MonthGrid(
                      state: calendarState,
                      onDayTap: (day) => _showDayAgenda(context, day, calendarState.eventsOn(day)),
                    ),
                  ),
                CalendarViewMode.week => _WeekList(state: calendarState),
                CalendarViewMode.day => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    child: DayAgenda(
                      day: calendarState.focusedDay,
                      events: calendarState.eventsOn(calendarState.focusedDay),
                    ),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.state, required this.onDayTap});

  final CalendarState state;
  final void Function(DateTime day) onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(state.focusedDay.year, state.focusedDay.month, 1);
    final daysInMonth = DateTime(state.focusedDay.year, state.focusedDay.month + 1, 0).day;
    // Sunday-first grid, matching CalendarController's week math.
    final leadingBlanks = firstOfMonth.weekday % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - (totalCells % 7)) % 7;
    final cellCount = totalCells + trailingBlanks;
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => Expanded(
                    child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ))
              .toList(),
        ),
        const SizedBox(height: Spacing.sm),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: cellCount,
            itemBuilder: (context, index) {
              final dayNumber = index - leadingBlanks + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final day = DateTime(state.focusedDay.year, state.focusedDay.month, dayNumber);
              final events = state.eventsOn(day);
              final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
              final eventTypes = events.map((e) => e.type).toSet();

              return InkWell(
                onTap: () => onDayTap(day),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday ? Theme.of(context).colorScheme.primaryContainer : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNumber'),
                      const SizedBox(height: 2),
                      if (eventTypes.isNotEmpty)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 2,
                          children: [
                            for (final type in eventTypes)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: type == CalendarEventType.meeting
                                      ? Theme.of(context).colorScheme.primary
                                      : const Color(0xFFFF9800),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeekList extends StatelessWidget {
  const _WeekList({required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final start = state.focusedDay.subtract(Duration(days: state.focusedDay.weekday % 7));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      children: [for (final day in days) _DaySection(day: day, events: state.eventsOn(day))],
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.events});

  final DateTime day;
  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMM d').format(day),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isToday ? scheme.primary : null,
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
          ),
          const SizedBox(height: Spacing.xs),
          DayAgenda(day: day, events: events),
        ],
      ),
    );
  }
}
