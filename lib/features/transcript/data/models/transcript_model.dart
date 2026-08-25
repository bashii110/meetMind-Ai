

import 'package:meetmind_ai/features/transcript/domain/entities/transcript.dart';

class TranscriptModel extends Transcript {
  const TranscriptModel({
    required super.id,
    required super.meetingId,
    required super.text,
    required super.createdAt,
    super.language,
  });

  factory TranscriptModel.fromJson(Map<String, dynamic> json) {
    return TranscriptModel(
      id: json['id'].toString(),
      meetingId: json['meeting_id'].toString(),
      text: json['text'] as String? ?? '',
      language: json['language'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
