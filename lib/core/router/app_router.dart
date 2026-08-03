import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/meetings/presentation/screens/create_edit_meeting_screen.dart';
import '../../features/meetings/presentation/screens/meeting_details_screen.dart';
import '../../features/meetings/presentation/screens/meeting_list_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
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
      final loc = state.matchedLocation;

      final isPreAuthRoute = loc == AppRoutes.onboarding ||
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgotPassword ||
          loc == AppRoutes.resetPassword;

      // Still resolving a possibly-stored session (AuthController.build()):
      // stay put on splash rather than redirecting anywhere yet, to avoid
      // a flash of the login screen for users who are actually signed in.
      if (status == AuthStatus.unknown) {
        return loc == AppRoutes.splash ? null : null;
      }

      if (status == AuthStatus.unauthenticated) {
        if (loc == AppRoutes.splash) return AppRoutes.onboarding;
        return isPreAuthRoute ? null : AppRoutes.login;
      }

      // Authenticated: keep signed-in users out of the pre-auth screens.
      if (loc == AppRoutes.splash || isPreAuthRoute) {
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
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.meetings,
        builder: (context, state) => const MeetingListScreen(),
      ),
      GoRoute(
        path: AppRoutes.meetingNew,
        builder: (context, state) => const CreateEditMeetingScreen(),
      ),
      GoRoute(
        path: AppRoutes.meetingDetails,
        builder: (context, state) => MeetingDetailsScreen(meetingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.meetingEdit,
        builder: (context, state) => CreateEditMeetingScreen(meetingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationListScreen(),
      ),

      // Phase 3+: register the real screens as each feature lands, e.g.
      // GoRoute(
      //   path: AppRoutes.recordMeeting,
      //   builder: (_, state) => RecordMeetingScreen(id: state.pathParameters['id']!),
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
