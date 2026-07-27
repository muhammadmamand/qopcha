import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// From Firebase project "qopchaapp" (package: com.shikposh.shik_posh).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        // Desktop uses the same Firebase project credentials.
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCQk-8ohIvN9Je_BysyO0hEiZHEbJEntqs',
    appId: '1:727891551013:android:449ff2f178a82c693ab0cc',
    messagingSenderId: '727891551013',
    projectId: 'qopchaapp',
    storageBucket: 'qopchaapp.firebasestorage.app',
  );

  /// Same project keys — add a Web app in Firebase Console for a real web appId.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCQk-8ohIvN9Je_BysyO0hEiZHEbJEntqs',
    appId: '1:727891551013:android:449ff2f178a82c693ab0cc',
    messagingSenderId: '727891551013',
    projectId: 'qopchaapp',
    storageBucket: 'qopchaapp.firebasestorage.app',
    authDomain: 'qopchaapp.firebaseapp.com',
  );

  /// Add an iOS app in Firebase Console, then replace these.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCQk-8ohIvN9Je_BysyO0hEiZHEbJEntqs',
    appId: '1:727891551013:ios:REPLACE_AFTER_ADDING_IOS_APP',
    messagingSenderId: '727891551013',
    projectId: 'qopchaapp',
    storageBucket: 'qopchaapp.firebasestorage.app',
    iosBundleId: 'com.shikposh.shikPosh',
  );
}
