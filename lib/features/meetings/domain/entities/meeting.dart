import 'package:equatable/equatable.dart';

class MeetingParticipant extends Equatable {
  const MeetingParticipant({
    required this.userId,
    required this.name,
    required this.email,
    required this.inviteStatus,
    this.avatar,
  });

  final String userId;
  final String name;
  final String email;
  final String inviteStatus; // pending | accepted | declined
  final String? avatar;

  @override
  List<Object?> get props => [userId, name, email, inviteStatus, avatar];
}

class Meeting extends Equatable {
  const Meeting({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.date,
    required this.priority,
    required this.status,
    this.description,
    this.time,
    this.location,
    this.onlineLink,
    this.category,
    this.ownerName,
    this.ownerId,
    this.tags = const [],
    this.participants = const [],
    this.participantCount = 0,
  });

  final String id;
  final String workspaceId;
  final String title;
  final String? description;
  final DateTime date;
  final String? time; // "HH:mm" — kept as a string; combine with `date` for a DateTime when needed
  final String? location;
  final String? onlineLink;
  final String priority; // low | medium | high
  final String? category;
  final String status; // draft | scheduled | completed | cancelled
  final String? ownerId;
  final String? ownerName;
  final List<String> tags;
  final List<MeetingParticipant> participants;
  final int participantCount;

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        title,
        description,
        date,
        time,
        location,
        onlineLink,
        priority,
        category,
        status,
        ownerId,
        ownerName,
        tags,
        participants,
        participantCount,
      ];
}
