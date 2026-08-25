import 'package:equatable/equatable.dart';

class Transcript extends Equatable {
  const Transcript({
    required this.id,
    required this.meetingId,
    required this.text,
    required this.createdAt,
    this.language,
  });

  final String id;
  final String meetingId;
  final String text;
  final String? language;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, meetingId, text, language, createdAt];
}
