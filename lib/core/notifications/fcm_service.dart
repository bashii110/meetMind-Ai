import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'FCM background message: ${message.messageId}',
  );
}

class FcmService {
  FcmService(this._dio);

  final Dio _dio;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize({
    void Function(Map<String, dynamic> data)? onNotificationTap,
    VoidCallback? onNotificationReceived,
  }) async {
    if (_initialized) return;

    await _initLocalNotifications(onNotificationTap);

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await messaging.getToken();

    await _registerToken(token);

    _tokenRefreshSubscription =
        messaging.onTokenRefresh.listen(_registerToken);

    _onMessageSubscription =
        FirebaseMessaging.onMessage.listen((message) async {
          await _showForegroundNotification(message);

          onNotificationReceived?.call();
        });

    _onMessageOpenedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(
              (message) {
            onNotificationTap?.call(message.data);
          },
        );

    final initialMessage =
    await messaging.getInitialMessage();

    if (initialMessage != null) {
      onNotificationTap?.call(initialMessage.data);
    }

    _initialized = true;
  }

  Future<void> _initLocalNotifications(
      void Function(Map<String, dynamic> data)? onNotificationTap,
      ) async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;

        if (payload == null || payload.isEmpty) {
          onNotificationTap?.call({});
          return;
        }

        try {
          final data =
          jsonDecode(payload) as Map<String, dynamic>;

          onNotificationTap?.call(data);
        } catch (e) {
          debugPrint(
            'Failed to parse notification payload: $e',
          );

          onNotificationTap?.call({});
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'meetmind_default',
      'MeetMind AI',
      description: 'Meeting and task notifications',
      importance: Importance.high,
    );

    final androidPlugin =
    _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      channel,
    );
  }

  Future<void> _showForegroundNotification(
      RemoteMessage message,
      ) async {
    debugPrint(
      '🔥 FCM FOREGROUND MESSAGE RECEIVED',
    );

    debugPrint(
      'Message ID: ${message.messageId}',
    );

    debugPrint(
      'Title: ${message.notification?.title}',
    );

    debugPrint(
      'Body: ${message.notification?.body}',
    );

    debugPrint(
      'Data: ${message.data}',
    );

    final notification = message.notification;

    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'meetmind_default',
      'MeetMind AI',
      channelDescription: 'Meeting and task notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _registerToken(String? token) async {
    if (token == null) return;

    try {
      await _dio.post(
        '/device-tokens',
        data: {
          'token': token,
          'platform': _platform,
        },
      );

      debugPrint(
        '✅ FCM token registered successfully',
      );
    } catch (e) {
      debugPrint(
        '❌ FCM token registration failed: $e',
      );
    }
  }

  String get _platform {
    if (kIsWeb) {
      return 'web';
    }

    return Platform.isIOS ? 'ios' : 'android';
  }

  Future<void> unregister() async {
    final token = await FirebaseMessaging.instance.getToken();

    // Stop all FCM listeners for the current authenticated user.
    await _tokenRefreshSubscription?.cancel();
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedAppSubscription?.cancel();

    _tokenRefreshSubscription = null;
    _onMessageSubscription = null;
    _onMessageOpenedAppSubscription = null;

    if (token == null) {
      _initialized = false;
      return;
    }

    try {
      await _dio.delete(
        '/device-tokens',
        data: {
          'token': token,
        },
      );

      debugPrint(
        '✅ FCM token unregistered successfully',
      );
    } catch (e) {
      debugPrint(
        '❌ FCM token unregister failed: $e',
      );
    }

    // Allow FCM to initialize again for the next logged-in user.
    _initialized = false;
  }
}