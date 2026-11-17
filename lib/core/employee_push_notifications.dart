import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> productionFirebaseBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

class EmployeePushNotifications {
  EmployeePushNotifications._();
  static final instance = EmployeePushNotifications._();
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const _channel = AndroidNotificationChannel(
    'quikboom_notifications',
    'QB Suite Notifications',
    description: 'Attendance and work updates',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  Dio? _dio;
  bool _initialized = false;
  StreamSubscription<String>? _tokenSubscription;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (_) => _openAttendance(),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onBackgroundMessage(
        productionFirebaseBackgroundHandler,
      );
      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _openAttendance());
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
        token,
      ) {
        final dio = _dio;
        if (dio != null) unawaited(_register(dio, token));
      });
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openAttendance());
      }
      _initialized = true;
    } catch (error) {
      debugPrint('[FCM][Production] Initialization failed: $error');
    }
  }

  Future<void> register(Dio dio) async {
    _dio = dio;
    if (!_initialized) await initialize();
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) await _register(dio, token);
    } catch (error) {
      debugPrint('[FCM][Production] Token registration failed: $error');
    }
  }

  Future<void> _register(Dio dio, String token) async {
    await dio.post(
      '/notifications/device-token',
      data: {
        'token': token,
        'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
        'deviceType': 'PRODUCTION_APP',
      },
    );
  }

  Future<void> unregister(Dio dio) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await dio.delete('/notifications/device-token', data: {'token': token});
      }
    } catch (error) {
      debugPrint('[FCM][Production] Token unregister failed: $error');
    }
    _dio = null;
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'QB Suite';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    if (body.isEmpty && title == 'QB Suite') return;
    await _local.show(
      message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'quikboom_notifications',
          'QB Suite Notifications',
          channelDescription: 'Attendance and work updates',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _openAttendance() {
    final context = navigatorKey.currentContext;
    if (context != null) GoRouter.of(context).go('/');
  }
}
