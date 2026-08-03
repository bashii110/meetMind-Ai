import '../../domain/entities/meeting.dart';

class MeetingParticipantModel extends MeetingParticipant {
  const MeetingParticipantModel({
    required super.userId,
    required super.name,
    required super.email,
    required super.inviteStatus,
    super.avatar,
  });

  factory MeetingParticipantModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return MeetingParticipantModel(
      userId: (user?['id'] ?? '').toString(),
      name: user?['name'] as String? ?? '',
      email: user?['email'] as String? ?? '',
      inviteStatus: json['invite_status'] as String? ?? 'pending',
      avatar: user?['avatar'] as String?,
    );
  }
}

class MeetingModel extends Meeting {
  const MeetingModel({
    required super.id,
    required super.workspaceId,
    required super.title,
    required super.date,
    required super.priority,
    required super.status,
    super.description,
    super.time,
    super.location,
    super.onlineLink,
    super.category,
    super.ownerId,
    super.ownerName,
    super.tags,
    super.participants,
    super.participantCount,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final tags = (json['tags'] as List?) ?? const [];
    final participants = (json['participants'] as List?) ?? const [];

    return MeetingModel(
      id: json['id'].toString(),
      workspaceId: json['workspace_id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String?,
      location: json['location'] as String?,
      onlineLink: json['online_link'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      category: json['category'] as String?,
      status: json['status'] as String? ?? 'draft',
      ownerId: owner?['id']?.toString(),
      ownerName: owner?['name'] as String?,
      tags: tags.map((t) => (t as Map<String, dynamic>)['name'] as String).toList(),
      participants: participants
          .map((p) => MeetingParticipantModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      participantCount: json['participant_count'] as int? ?? participants.length,
    );
  }
}
