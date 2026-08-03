import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';

/// Route-guard signal derived from [authControllerProvider]. Kept as its
/// own small enum (rather than having app_router.dart watch AsyncValue<AppUser?>
/// directly) so the router's redirect logic reads as intent, not
/// AsyncValue-branching boilerplate.
///
/// This is a deliberate exception to the usual "core doesn't depend on
/// features" direction: routing is inherently cross-cutting and needs to
/// know about auth state. Every other feature should depend on core, not
/// the other way around.
enum AuthStatus { unknown, authenticated, unauthenticated }

final authStatusProvider = Provider<AuthStatus>((ref) {
  final auth = ref.watch(authControllerProvider);

  return auth.when(
    data: (user) => user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    loading: () => AuthStatus.unknown,
    error: (_, __) => AuthStatus.unauthenticated,
  );
});
