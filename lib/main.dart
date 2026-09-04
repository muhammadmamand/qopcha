import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Marketplace data uses the Contabo VPS API.
  // Firebase is optional and only used for phone push notifications.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Must be registered before runApp (background isolate entry).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationService.instance.initialize();
  } catch (e, st) {
    debugPrint('Firebase/push optional init failed: $e\n$st');
  }
  runApp(
    const ProviderScope(
      child: QopchaApp(),
    ),
  );
}
