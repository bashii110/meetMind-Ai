import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import 'app_routes.dart';
import 'auth_status.dart';

/// Declarative, deep-linkable navigation with auth guards — ARCHITECTURE.md
/// 2.2. Additional routes (meetings, tasks, calendar, ...) get added to
/// `routes` as each feature lands; keep this file as the single place
/// route -> screen wiring happens.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Rebuild the router's matched route whenever auth status changes, so a
  // logout mid-session immediately redirects instead of waiting for the
  // next navigation event.
  final authListenable = _AuthStatusListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final status = ref.read(authStatusProvider);
      final onAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.onboarding ||
          // TODO(Phase 1): remove — dashboard is only unguarded until the
          // real login screen/route exists to redirect to.
          state.matchedLocation == AppRoutes.dashboard;

      if (status != AuthStatus.authenticated && !onAuthRoute) {
        return AppRoutes.login;
      }
      if (status == AuthStatus.authenticated &&
          state.matchedLocation == AppRoutes.login) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),

      // Phase 1+: register the real screens as each feature lands, e.g.
      // GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      // GoRoute(path: AppRoutes.meetings, builder: (_, __) => const MeetingListScreen()),
      // GoRoute(
      //   path: AppRoutes.meetingDetails,
      //   builder: (_, state) => MeetingDetailsScreen(id: state.pathParameters['id']!),
      // ),
    ],
  );
});

/// Bridges Riverpod's [authStatusProvider] to GoRouter's ChangeNotifier-based
/// `refreshListenable` API.
class _AuthStatusListenable extends ChangeNotifier {
  _AuthStatusListenable(Ref ref) {
    ref.listen(authStatusProvider, (_, __) => notifyListeners());
  }
}
