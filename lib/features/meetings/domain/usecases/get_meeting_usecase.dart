import '../entities/meeting.dart';
import '../repositories/meeting_repository.dart';

class GetMeetingUseCase {
  const GetMeetingUseCase(this._repository);

  final MeetingRepository _repository;

  Future<Meeting> call(String id) => _repository.getById(id);
}
