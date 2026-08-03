import '../../../auth/domain/entities/app_user.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<AppUser> call() => _repository.getProfile();
}
