import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/calendar_event.dart';

/// DESIGN.md 3.8: "Tapping a day reveals a bottom sheet with that day's
/// agenda." Also reused inline for the Day view itself, so the month
/// grid's bottom sheet and the full Day screen render identically.
class DayAgenda extends StatelessWidget {
  const DayAgenda({super.key, required this.day, required this.events});

  final DateTime day;
  final List<CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Text(
          'Nothing scheduled for ${DateFormat.yMMMd().format(day)}.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _EventTile(event: events[index]),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final isMeeting = event.type == CalendarEventType.meeting;
    final color = isMeeting ? Theme.of(context).colorScheme.primary : const Color(0xFFFF9800);

    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(isMeeting ? Icons.event_outlined : Icons.flag_outlined, size: 18, color: color),
      ),
      title: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(event.allDay ? 'All day' : DateFormat.jm().format(event.dateTime)),
      onTap: () {
        Navigator.of(context).maybePop(); // close the bottom sheet, if this was opened as one
        if (isMeeting) {
          context.push(AppRoutes.meetingDetailsPath(event.id));
        } else {
          context.push(AppRoutes.taskDetailsPath(event.id));
        }
      },
    );
  }
}
