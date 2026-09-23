import '../../features/meetings/domain/entities/meeting.dart';
import '../../features/tasks/presentation/providers/task_stats_provider.dart';

/// Heuristic, fully client-side productivity nudges for the dashboard —
/// PHASES.md Phase 12's "productivity recommendations" bonus feature,
/// derived from data already on screen rather than a second AI call.
/// Order matters a little (most actionable first) but every tip is
/// independent, so callers can just render whichever ones come back.
List<String> buildProductivityTips({
  required TaskStats taskStats,
  required List<Meeting> upcomingMeetings,
}) {
  final tips = <String>[];

  if (taskStats.pending > 5) {
    tips.add(
      'You have ${taskStats.pending} pending tasks — consider tackling the highest-priority ones first.',
    );
  } else if (taskStats.pending == 0 && taskStats.completed > 0) {
    tips.add('Inbox zero on tasks — nice work.');
  }

  final today = DateTime.now();
  final todayCount = upcomingMeetings
      .where((m) => m.date.year == today.year && m.date.month == today.month && m.date.day == today.day)
      .length;

  if (todayCount >= 3) {
    tips.add('You have $todayCount meetings today — try blocking focus time between them.');
  }

  if (taskStats.completed > 0 && taskStats.pending > 0) {
    final ratio = taskStats.completed / (taskStats.completed + taskStats.pending);
    if (ratio >= 0.8) {
      tips.add("You're clearing ${(ratio * 100).round()}% of your tasks — keep the momentum going.");
    }
  }

  if (upcomingMeetings.isEmpty && taskStats.pending == 0 && taskStats.completed == 0) {
    tips.add('Record your first meeting to start getting AI summaries and task suggestions.');
  }

  return tips;
}
