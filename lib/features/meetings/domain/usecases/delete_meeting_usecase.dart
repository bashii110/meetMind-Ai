import '../repositories/meeting_repository.dart';

class DeleteMeetingUseCase {
  const DeleteMeetingUseCase(this._repository);

  final MeetingRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
