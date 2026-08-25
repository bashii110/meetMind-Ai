import 'package:equatable/equatable.dart';

/// DESIGN.md 3.6: "Meeting Mood (shown as a small sentiment badge)."
enum MeetingMood { positive, neutral, tense }

class MeetingSummary extends Equatable {
  const MeetingSummary({
    required this.id,
    required this.meetingId,
    required this.executiveSummary,
    required this.bulletSummary,
    required this.decisions,
    required this.risks,
    required this.nextSteps,
    required this.deadlines,
    required this.mood,
    required this.createdAt,
  });

  final String id;
  final String meetingId;
  final String executiveSummary;
  final List<String> bulletSummary;
  final List<String> decisions;
  final List<String> risks;
  final List<String> nextSteps;
  final List<String> deadlines;
  final MeetingMood mood;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        meetingId,
        executiveSummary,
        bulletSummary,
        decisions,
        risks,
        nextSteps,
        deadlines,
        mood,
        createdAt,
      ];
}
