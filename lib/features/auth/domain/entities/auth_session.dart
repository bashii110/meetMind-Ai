import 'app_user.dart';

/// Result of any auth operation that issues tokens (login/register/refresh).
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AppUser user;
  final String accessToken;
  final String refreshToken;
}
