import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import 'auth_providers.dart';

/// Single source of truth for "who is signed in, if anyone." `null` data
/// means unauthenticated; loading means we're still checking a stored
/// session; error means the last action (login/register/etc.) failed.
///
/// core/router/auth_status.dart derives its route-guard decisions from
/// this controller's state, so login/logout here immediately reflects in
/// navigation without any extra wiring.
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    // App start: is there a still-valid stored session?
    return ref.read(getCurrentUserUseCaseProvider)();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(loginUseCaseProvider)(email: email, password: password);
      return session.user;
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? timezone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(registerUseCaseProvider)(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        timezone: timezone,
      );
      return session.user;
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(googleLoginUseCaseProvider)();
      return session.user;
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider)();
    state = const AsyncData(null);
  }

  Future<void> forgotPassword(String email) {
    return ref.read(forgotPasswordUseCaseProvider)(email);
  }

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    return ref.read(resetPasswordUseCaseProvider)(
      token: token,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  /// Lets other features (e.g. profile updates) patch the cached user
  /// without a full re-fetch.
  void setUser(AppUser user) => state = AsyncData(user);
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);
