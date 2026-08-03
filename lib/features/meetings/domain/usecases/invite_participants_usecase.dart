import '../repositories/meeting_repository.dart';

class InviteParticipantsUseCase {
  const InviteParticipantsUseCase(this._repository);

  final MeetingRepository _repository;

  Future<List<String>> call(String meetingId, List<String> emails) {
    return _repository.inviteParticipants(meetingId, emails);
  }
}
