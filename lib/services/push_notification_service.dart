import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../models/app_notification.dart';
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

Future<void> _ensureLocalPluginReady() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _localNotifications.initialize(
    settings: const InitializationSettings(android: androidInit, iOS: iosInit),
  );
  if (!kIsWeb && Platform.isAndroid) {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }
}

Future<void> _showRemoteAsLocal(RemoteMessage message) async {
  final title = (message.notification?.title ??
          message.data['title'] ??
          'قۆپچە')
      .toString()
      .trim();
  final body =
      (message.notification?.body ?? message.data['body'] ?? '').toString();
  if (title.isEmpty && body.trim().isEmpty) return;

  await _ensureLocalPluginReady();
  await _localNotifications.show(
    id: message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title.isEmpty ? 'قۆپچە' : title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(message.data),
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  // Data-only (and some OEMs) need an explicit local notification.
  try {
    await _showRemoteAsLocal(message);
  } catch (e) {
    debugPrint('Background notification display failed: $e');
  }
}

/// Optional FCM push. Marketplace data lives on the Contabo API.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging? _messaging;
  bool _initialized = false;
  DateTime? _localAlertFloor;
  final Set<String> _alertedIds = {};
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
      // Background handler is registered from main() before runApp.
    } catch (e) {
      debugPrint('Push init skipped: $e');
      return;
    }
    _initialized = true;
    _localAlertFloor = DateTime.now();

    await _ensureLocalPluginReady();
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
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

    FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showRemoteAsLocal(message));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationOpened?.call(message);
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      onNotificationOpened?.call(initial);
    }
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
      if (!kIsWeb && Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
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
      // Reset floor so we don't replay the whole inbox as banners.
      _localAlertFloor = DateTime.now();
      _alertedIds.clear();
    } catch (e) {
      debugPrint('Push sync skipped: $e');
    }
  }

  Future<void> clearUser() async {
    final messaging = _messaging;
    _alertedIds.clear();
    _localAlertFloor = DateTime.now();
    if (messaging == null) return;
    try {
      await messaging.unsubscribeFromTopic(kNewProductsTopic);
    } catch (_) {}
  }

  /// While the app process is alive, show a system banner for brand-new
  /// inbox items (covers the gap before Contabo FCM credentials are set).
  Future<void> alertForNewInboxItems(List<AppNotification> list) async {
    if (!_supported || !_initialized) return;
    final floor = _localAlertFloor ??= DateTime.now();
    final fresh = list
        .where(
          (n) =>
              n.createdAt.isAfter(floor) &&
              !_alertedIds.contains(n.id) &&
              n.title.trim().isNotEmpty,
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (fresh.isEmpty) return;

    for (final n in fresh) {
      _alertedIds.add(n.id);
      try {
        await _localNotifications.show(
          id: n.id.hashCode & 0x7fffffff,
          title: n.title,
          body: n.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode({
            'type': n.type,
            'productId': n.productId,
            'notificationId': n.id,
          }),
        );
      } catch (e) {
        debugPrint('Local inbox alert failed: $e');
      }
    }
    final newest = fresh.last.createdAt;
    if (newest.isAfter(floor)) {
      _localAlertFloor = newest;
    }
  }
}
