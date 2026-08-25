import 'package:meetmind_ai/features/recording/domain/entities/recording_exceptions.dart';
import 'package:meetmind_ai/features/recording/domain/repositories/recording_repository.dart';

class StartRecordingUseCase {
  const StartRecordingUseCase(this._repository);

  final RecordingRepository _repository;

  Future<void> call() async {
    final granted = await _repository.hasPermission();
    if (!granted) {
      throw const RecordingPermissionDeniedException();
    }
    await _repository.start();
  }
}
