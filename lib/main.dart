import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/connectivity_controller.dart';
import 'core/notifications/fcm_providers.dart';
import 'core/notifications/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/router/auth_status.dart';
import 'core/storage/local_db.dart';
import 'core/sync/outbox_sync_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_banner.dart';
import 'features/notifications/presentation/providers/notifications_controller.dart';
import 'firebase_options.dart';

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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint(
        'Firebase initialization failed: $e',
      );
    }
  }
}

/// Phase 10 (ARCHITECTURE.md 2.3): resolves the real connectivity state
/// once at startup (ConnectivityController.build() starts optimistic),
/// then replays anything left in the outbox from a previous offline
/// session. Watching this once in MeetMindApp.build is enough to run it
/// exactly once — Riverpod caches the FutureProvider's result for the
/// rest of the app's lifetime.
final _startupSyncProvider = FutureProvider<void>((ref) async {
  await ref.read(connectivityControllerProvider.notifier).refresh();
  if (ref.read(isOnlineProvider)) {
    await ref.read(outboxSyncManagerProvider.notifier).syncNow();
  }
});

class MeetMindApp extends ConsumerWidget {
  const MeetMindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ref.watch(_startupSyncProvider);

    // FCM registration needs an authenticated session (POST /device-tokens
    // requires auth:sanctum), so it's triggered off auth state rather than
    // unconditionally at startup — see FcmService's class doc.
    ref.listen(authStatusProvider, (previous, next) {
      final fcm = ref.read(fcmServiceProvider);

      if (next == AuthStatus.authenticated) {
        fcm.initialize(
          onNotificationTap: (data) =>
              _handleNotificationTap(ref, data),
          onNotificationReceived: () {
            ref.invalidate(notificationsControllerProvider);
          },
        );
      }
    });

    // Phase 10: reconnecting kicks off a sync pass automatically, so
    // queued offline changes don't sit around waiting for the user to
    // notice the sync chip and tap it themselves.
    ref.listen(connectivityControllerProvider, (previous, next) {
      if (previous == ConnectivityStatus.offline && next == ConnectivityStatus.online) {
        ref.read(outboxSyncManagerProvider.notifier).syncNow();
      }
    });

    return MaterialApp.router(
      title: 'MeetMind AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      // Phase 10: a persistent offline banner sits above every screen —
      // wrapping here, rather than in each Scaffold, means new screens
      // get it for free.
      builder: (context, child) => Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
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
