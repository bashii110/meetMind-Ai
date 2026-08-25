import 'package:meetmind_ai/features/recording/domain/repositories/audio_upload_repository.dart';


class RetryUploadUseCase {
  const RetryUploadUseCase(this._repository);

  final AudioUploadRepository _repository;

  Future<void> call(String pendingUploadId) => _repository.upload(pendingUploadId);
}
