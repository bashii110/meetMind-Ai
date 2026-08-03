import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class GoogleLoginUseCase {
  const GoogleLoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call() => _repository.loginWithGoogle();
}
