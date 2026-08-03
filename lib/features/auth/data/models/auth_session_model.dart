import '../../domain/entities/auth_session.dart';
import 'app_user_model.dart';

/// Maps POST /auth/{register,login,google,refresh}'s
/// `{ user, access_token, refresh_token, token_type }` response body.
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.user,
    required super.accessToken,
    required super.refreshToken,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      user: AppUserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }
}
