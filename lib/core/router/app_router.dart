import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/meetings/presentation/screens/create_edit_meeting_screen.dart';
import '../../features/meetings/presentation/screens/meeting_details_screen.dart';
import '../../features/meetings/presentation/screens/meeting_list_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/recording/presentation/screens/record_meeting_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/tasks/presentation/screens/create_edit_task_screen.dart';
import '../../features/tasks/presentation/screens/task_details_screen.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/workspace/presentation/screens/create_edit_workspace_screen.dart';
import '../../features/workspace/presentation/screens/workspace_details_screen.dart';
import '../../features/workspace/presentation/screens/workspace_list_screen.dart';
import 'app_routes.dart';
import 'auth_status.dart';

/// Declarative, deep-linkable navigation with auth guards — ARCHITECTURE.md
/// 2.2. Additional routes get added to `routes` as each feature lands;
/// keep this file as the single place route -> screen wiring happens.
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
        path: AppRoutes.recordMeeting,
        builder: (context, state) => RecordMeetingScreen(
          meetingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationListScreen(),
      ),
      // Phase 5: Smart Task Manager (SRD FR-7.x).
      GoRoute(
        path: AppRoutes.tasks,
        builder: (context, state) => const TaskListScreen(),
      ),
      GoRoute(
        path: AppRoutes.taskNew,
        builder: (context, state) => const CreateEditTaskScreen(),
      ),
      GoRoute(
        path: AppRoutes.taskDetails,
        builder: (context, state) => TaskDetailsScreen(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.taskEdit,
        builder: (context, state) => CreateEditTaskScreen(taskId: state.pathParameters['id']!),
      ),
      // Phase 6: Calendar (DESIGN.md 3.8).
      GoRoute(
        path: AppRoutes.calendar,
        builder: (context, state) => const CalendarScreen(),
      ),
      // Phase 7: Team Collaboration & Workspaces (SRD FR-10.x).
      GoRoute(
        path: AppRoutes.workspace,
        builder: (context, state) => const WorkspaceListScreen(),
      ),
      GoRoute(
        path: AppRoutes.workspaceNew,
        builder: (context, state) => const CreateEditWorkspaceScreen(),
      ),
      GoRoute(
        path: AppRoutes.workspaceDetails,
        builder: (context, state) => WorkspaceDetailsScreen(workspaceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.workspaceEdit,
        builder: (context, state) => CreateEditWorkspaceScreen(workspaceId: state.pathParameters['id']!),
      ),
      // Phase 8: AI Chat Assistant & Search (SRD FR-11.x/FR-12.x). The
      // assistant itself has no standalone route — it lives as a tab on
      // MeetingDetailsScreen (see AppRoutes.meetingDetails).
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      // Phase 9: Analytics & Admin (SRD FR-13.x/FR-16.x). AdminScreen
      // gates its own content client-side to system admins; the route
      // itself stays open so a non-admin gets a friendly "no access"
      // message instead of a raw 404-style dead link.
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminScreen(),
      ),
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
