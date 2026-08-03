import '../repositories/meeting_repository.dart';

class RespondToInvitationUseCase {
  const RespondToInvitationUseCase(this._repository);

  final MeetingRepository _repository;

  Future<void> call(String meetingId, String status) {
    return _repository.respondToInvitation(meetingId, status);
  }
}
