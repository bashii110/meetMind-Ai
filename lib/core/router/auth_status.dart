import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimal auth-status signal used by the router's redirect logic.
///
/// This is intentionally provisional: once `features/auth` lands (Phase 1),
/// replace this with the real AsyncNotifier that tracks the authenticated
/// user + tokens, and update `router.dart`'s `refreshListenable` to listen
/// to it. Kept here (not inside features/auth) only so core/router has
/// something concrete to depend on in this scaffold.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  void setAuthenticated() => state = AuthStatus.authenticated;

  void setUnauthenticated() => state = AuthStatus.unauthenticated;
}

final authStatusProvider =
    NotifierProvider<AuthStatusNotifier, AuthStatus>(AuthStatusNotifier.new);
