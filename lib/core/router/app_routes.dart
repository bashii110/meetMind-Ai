/// Central route paths so screens/features never hardcode strings.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  static const dashboard = '/dashboard';
  static const meetings = '/meetings';
  static const meetingNew = '/meetings/new';
  static const meetingDetails = '/meetings/:id';
  static const meetingEdit = '/meetings/:id/edit';
  static const recordMeeting = '/meetings/:id/record';
  static const aiSummary = '/meetings/:id/summary';
  static const transcript = '/meetings/:id/transcript';

  static const tasks = '/tasks';
  static const taskNew = '/tasks/new';
  static const taskDetails = '/tasks/:id';
  static const taskEdit = '/tasks/:id/edit';

  static const calendar = '/calendar';
  static const notifications = '/notifications';

  // Phase 7: Team Collaboration & Workspaces (SRD FR-10.x).
  static const workspace = '/workspace';
  static const workspaceNew = '/workspace/new';
  static const workspaceDetails = '/workspace/:id';
  static const workspaceEdit = '/workspace/:id/edit';

  static const search = '/search';
  static const analytics = '/analytics';
  static const profile = '/profile';
  static const settings = '/settings';
  static const admin = '/admin';

  static String meetingDetailsPath(String id) => '/meetings/$id';
  static String meetingEditPath(String id) => '/meetings/$id/edit';
  static String recordMeetingPath(String id) => '/meetings/$id/record';
  static String aiSummaryPath(String id) => '/meetings/$id/summary';
  static String taskDetailsPath(String id) => '/tasks/$id';
  static String taskEditPath(String id) => '/tasks/$id/edit';
  static String workspaceDetailsPath(String id) => '/workspace/$id';
  static String workspaceEditPath(String id) => '/workspace/$id/edit';
}
