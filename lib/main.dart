import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/fcm_providers.dart';
import 'core/notifications/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/router/auth_status.dart';
import 'core/storage/local_db.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initLocalDb();
  await _initializeFirebase();

  runApp(const ProviderScope(child: MeetMindApp()));
}

/// PHASES.md Phase 6. Wrapped in try/catch because this only works once
/// native Firebase config is in place — `google-services.json` (Android)
/// and `GoogleService-Info.plist` (iOS), added via the Firebase console,
/// same as the pre-existing comment this replaces already anticipated.
/// Without them, push notifications are simply unavailable and the rest
/// of the app should keep working — see FcmService's class doc.
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase not configured yet, push notifications are disabled: $e');
    }
  }
}

class MeetMindApp extends ConsumerWidget {
  const MeetMindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // FCM registration needs an authenticated session (POST /device-tokens
    // requires auth:sanctum), so it's triggered off auth state rather than
    // unconditionally at startup — see FcmService's class doc.
    ref.listen(authStatusProvider, (previous, next) {
      final fcm = ref.read(fcmServiceProvider);
      if (next == AuthStatus.authenticated) {
        fcm.initialize(onNotificationTap: (data) => _handleNotificationTap(ref, data));
      } else if (next == AuthStatus.unauthenticated && previous == AuthStatus.authenticated) {
        fcm.unregister();
      }
    });

    return MaterialApp.router(
      title: 'MeetMind AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

/// Routes a tapped push notification to the relevant screen. `data` is the
/// FCM message's data payload — see backend/app/Services/NotificationService.php's
/// `notify()`, which always includes `type` plus whatever ids the specific
/// notification type carries (`meeting_id`, `task_id`, ...).
void _handleNotificationTap(WidgetRef ref, Map<String, dynamic> data) {
  final router = ref.read(appRouterProvider);
  final type = data['type'] as String?;

  switch (type) {
    case 'meeting_invitation':
    case 'meeting_reminder':
      final meetingId = data['meeting_id'];
      if (meetingId != null) router.push('/meetings/$meetingId');
      break;
    case 'task_assigned':
    case 'task_completed':
    case 'deadline':
      final taskId = data['task_id'];
      if (taskId != null) router.push('/tasks/$taskId');
      break;
    default:
      router.push('/notifications');
  }
}
