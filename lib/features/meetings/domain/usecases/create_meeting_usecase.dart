import '../entities/meeting.dart';
import '../repositories/meeting_repository.dart';

class CreateMeetingUseCase {
  const CreateMeetingUseCase(this._repository);

  final MeetingRepository _repository;

  Future<Meeting> call({
    required String title,
    String? description,
    required DateTime date,
    String? time,
    String? location,
    String? onlineLink,
    String priority = 'medium',
    String? category,
    List<String> tags = const [],
    List<String> participantEmails = const [],
    String? workspaceId,
  }) {
    return _repository.create(
      title: title,
      description: description,
      date: date,
      time: time,
      location: location,
      onlineLink: onlineLink,
      priority: priority,
      category: category,
      tags: tags,
      participantEmails: participantEmails,
      workspaceId: workspaceId,
    );
  }
}
