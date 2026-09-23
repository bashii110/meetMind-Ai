import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/core/insights/meeting_score.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/meeting_summary.dart';

MeetingSummary _summary({
  MeetingMood mood = MeetingMood.neutral,
  List<String> decisions = const [],
  List<String> nextSteps = const [],
  List<String> deadlines = const [],
  List<String> risks = const [],
}) {
  return MeetingSummary(
    id: 's1',
    meetingId: 'm1',
    executiveSummary: 'Summary',
    bulletSummary: const [],
    decisions: decisions,
    risks: risks,
    nextSteps: nextSteps,
    deadlines: deadlines,
    mood: mood,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  test('a summary with nothing but a neutral mood scores 15', () {
    final score = MeetingScore.fromSummary(_summary());
    expect(score.value, 15);
    expect(score.label, 'Needs follow-up');
  });

  test('a fully-loaded positive summary scores 100 and caps there', () {
    final score = MeetingScore.fromSummary(_summary(
      mood: MeetingMood.positive,
      decisions: ['Ship it'],
      nextSteps: ['Follow up Friday'],
      deadlines: ['2026-02-01'],
      risks: ['Vendor delay'],
    ));
    expect(score.value, 100);
    expect(score.label, 'Excellent');
  });

  test('a tense mood contributes nothing, but other factors still count', () {
    final score = MeetingScore.fromSummary(_summary(mood: MeetingMood.tense, decisions: ['Ship it']));
    expect(score.value, 20);
  });

  test('the factors list has one entry per contributing item', () {
    final score = MeetingScore.fromSummary(_summary(mood: MeetingMood.positive, decisions: ['A']));
    expect(score.factors.length, 2);
  });
}
