import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../models/user_model.dart';
import 'api_client.dart';

const kNewProductsTopic = 'new_products';

const _androidChannel = AndroidNotificationChannel(
  'qopcha_new_products',
  'بەرهەمی نوێ',
  description: 'ئاگاداری کاتێک دووکان بەرهەمی نوێ زیاد دەکات',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
}

/// Optional FCM push. Marketplace data lives on the Contabo API.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging? _messaging;
  bool _initialized = false;
  void Function(RemoteMessage message)? onNotificationOpened;

  bool get _supported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_initialized || !_supported) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Push init skipped: $e');
      return;
    }
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final raw = response.payload;
        if (raw == null || raw.isEmpty) return;
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          onNotificationOpened?.call(
            RemoteMessage(data: data.map((k, v) => MapEntry(k, '$v'))),
          );
        } catch (_) {}
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'قۆپچە';
      final body = message.notification?.body ?? '';
      unawaited(
        _localNotifications.show(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationOpened?.call(message);
    });
  }

  Future<void> syncForUser(UserModel? user) async {
    await syncUser(user);
  }

  Future<void> clearForLogout() async {
    await clearUser();
  }

  Future<void> syncUser(UserModel? user) async {
    final messaging = _messaging;
    if (!_initialized || messaging == null || user == null) return;
    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      if (user.isCustomer) {
        await messaging.subscribeToTopic(kNewProductsTopic);
      } else {
        await messaging.unsubscribeFromTopic(kNewProductsTopic);
      }
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await ApiClient.instance.patchJson('/api/auth/me', {
        'fcmToken': token,
        'fcmUpdatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Push sync skipped: $e');
    }
  }

  Future<void> clearUser() async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      await messaging.unsubscribeFromTopic(kNewProductsTopic);
    } catch (_) {}
  }
}
