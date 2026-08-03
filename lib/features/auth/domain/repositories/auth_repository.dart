import '../entities/app_user.dart';
import '../entities/auth_session.dart';

/// Implemented by data/repositories/auth_repository_impl.dart. Use cases and
/// the presentation layer depend on this abstraction, never the impl
/// directly (ARCHITECTURE.md 2.1).
abstract interface class AuthRepository {
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? timezone,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  /// Runs the native Google sign-in flow, then exchanges the resulting
  /// Google access token with the backend for a MeetMind session.
  Future<AuthSession> loginWithGoogle();

  Future<void> logout();

  /// Reads a stored access token (if any) and fetches the current user —
  /// used on app start to decide whether the session is still valid.
  /// Returns null if there's no stored session or it's no longer valid.
  Future<AppUser?> getCurrentUser();

  Future<void> forgotPassword(String email);

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  });
}
