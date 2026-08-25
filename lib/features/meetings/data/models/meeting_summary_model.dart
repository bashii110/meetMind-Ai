

import 'package:meetmind_ai/features/meetings/domain/entities/meeting_summary.dart';

class MeetingSummaryModel extends MeetingSummary {
  const MeetingSummaryModel({
    required super.id,
    required super.meetingId,
    required super.executiveSummary,
    required super.bulletSummary,
    required super.decisions,
    required super.risks,
    required super.nextSteps,
    required super.deadlines,
    required super.mood,
    required super.createdAt,
  });

  factory MeetingSummaryModel.fromJson(Map<String, dynamic> json) {
    return MeetingSummaryModel(
      id: json['id'].toString(),
      meetingId: json['meeting_id'].toString(),
      executiveSummary: json['executive_summary'] as String? ?? '',
      bulletSummary: _stringList(json['bullet_summary']),
      decisions: _stringList(json['decisions']),
      risks: _stringList(json['risks']),
      nextSteps: _stringList(json['next_steps']),
      deadlines: _stringList(json['deadlines']),
      mood: _parseMood(json['mood'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  static MeetingMood _parseMood(String? raw) {
    switch (raw) {
      case 'positive':
        return MeetingMood.positive;
      case 'tense':
        return MeetingMood.tense;
      case 'neutral':
      default:
        return MeetingMood.neutral;
    }
  }
}
