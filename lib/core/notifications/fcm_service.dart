import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// A push that arrives while the app is fully backgrounded/terminated is
/// handled entirely by the OS, but FCM still requires a top-level (or
/// static) handler to be registered via `onBackgroundMessage`, or it
/// throws. MeetMind's pushes always include a `notification` payload (see
/// backend/app/Services/PushNotificationService.php), which the OS already
/// surfaces on its own — so this only needs to exist, not do anything.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// PHASES.md Phase 6: "Firebase Cloud Messaging integration ... Flutter
/// receive/display." Requests notification permission, registers this
/// device's FCM token with the backend (POST /device-tokens — see
/// backend/app/Http/Controllers/Api/V1/DeviceTokenController.php), and
/// shows foreground pushes as local notifications, since FCM doesn't
/// surface a system notification banner while the app is in the
/// foreground the way it does in the background.
///
/// Deliberately a plain class, not a Riverpod provider that does its work
/// eagerly: initialization needs to be triggered explicitly once someone
/// is actually signed in (registering a device token requires
/// `auth:sanctum`), which `MeetMindApp` does by listening to
/// `authStatusProvider` — see lib/main.dart.
class FcmService {
  FcmService(this._dio);

  final Dio _dio;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize({void Function(Map<String, dynamic> data)? onNotificationTap}) async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // Declined — nothing more to do; re-prompting is an OS-level
      // setting from here on, not something the app can trigger again.
      return;
    }

    await _registerToken(await messaging.getToken());
    messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) => onNotificationTap?.call(message.data));

    // A push that launched the app from a fully terminated state.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      onNotificationTap?.call(initialMessage.data);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'meetmind_default',
      'MeetMind AI',
      channelDescription: 'Meeting and task notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _localNotifications.show(message.hashCode, notification.title, notification.body, details);
  }

  Future<void> _registerToken(String? token) async {
    if (token == null) return;
    try {
      await _dio.post('/device-tokens', data: {'token': token, 'platform': _platform});
    } catch (_) {
      // Best-effort — a failed registration just means this device won't
      // receive pushes until the next successful attempt (next token
      // refresh or app launch); it shouldn't block startup or login.
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    return Platform.isIOS ? 'ios' : 'android';
  }

  /// Called on logout so a signed-out device stops receiving pushes meant
  /// for the account that was just signed out of.
  Future<void> unregister() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await _dio.delete('/device-tokens', data: {'token': token});
    } catch (_) {
      // Best-effort on logout too.
    }
  }
}
