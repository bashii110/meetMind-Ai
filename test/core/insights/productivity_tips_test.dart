import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/core/insights/productivity_tips.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/meeting.dart';
import 'package:meetmind_ai/features/tasks/presentation/providers/task_stats_provider.dart';

Meeting _meeting(DateTime date) {
  return Meeting(id: 'm', workspaceId: 'w', title: 'M', date: date, priority: 'medium', status: 'scheduled');
}

void main() {
  test('suggests prioritizing when pending tasks pile up', () {
    final tips = buildProductivityTips(
      taskStats: const TaskStats(pending: 8, completed: 2),
      upcomingMeetings: const [],
    );
    expect(tips.any((t) => t.contains('pending tasks')), isTrue);
  });

  test('congratulates inbox zero', () {
    final tips = buildProductivityTips(
      taskStats: const TaskStats(pending: 0, completed: 5),
      upcomingMeetings: const [],
    );
    expect(tips.any((t) => t.contains('Inbox zero')), isTrue);
  });

  test('flags a heavy meeting day', () {
    final today = DateTime.now();
    final tips = buildProductivityTips(
      taskStats: const TaskStats(pending: 1, completed: 1),
      upcomingMeetings: [_meeting(today), _meeting(today), _meeting(today)],
    );
    expect(tips.any((t) => t.contains('meetings today')), isTrue);
  });

  test('returns an onboarding nudge when everything is empty', () {
    final tips = buildProductivityTips(
      taskStats: const TaskStats(pending: 0, completed: 0),
      upcomingMeetings: const [],
    );
    expect(tips, isNotEmpty);
    expect(tips.any((t) => t.contains('Record your first meeting')), isTrue);
  });
}
