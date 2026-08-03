import '../entities/meeting.dart';
import '../repositories/meeting_repository.dart';

class UpdateMeetingUseCase {
  const UpdateMeetingUseCase(this._repository);

  final MeetingRepository _repository;

  Future<Meeting> call(
    String id, {
    String? title,
    String? description,
    DateTime? date,
    String? time,
    String? location,
    String? onlineLink,
    String? priority,
    String? category,
    List<String>? tags,
  }) {
    return _repository.update(
      id,
      title: title,
      description: description,
      date: date,
      time: time,
      location: location,
      onlineLink: onlineLink,
      priority: priority,
      category: category,
      tags: tags,
    );
  }
}
