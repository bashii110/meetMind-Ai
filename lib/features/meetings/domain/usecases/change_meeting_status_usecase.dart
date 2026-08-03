import '../entities/meeting.dart';
import '../repositories/meeting_repository.dart';

class ChangeMeetingStatusUseCase {
  const ChangeMeetingStatusUseCase(this._repository);

  final MeetingRepository _repository;

  Future<Meeting> call(String id, String status) => _repository.changeStatus(id, status);
}
