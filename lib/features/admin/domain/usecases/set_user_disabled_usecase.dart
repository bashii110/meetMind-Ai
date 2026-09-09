import '../entities/admin_user.dart';
import '../repositories/admin_repository.dart';

class SetUserDisabledUseCase {
  const SetUserDisabledUseCase(this._repository);

  final AdminRepository _repository;

  Future<AdminUser> call(String userId, bool disabled) => _repository.setUserDisabled(userId, disabled);
}
