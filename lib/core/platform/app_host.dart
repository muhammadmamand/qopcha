import 'package:flutter/foundation.dart';

/// Host / delivery channel helpers.
///
/// On **web**, this project ships as the separate **Admin Console** website by
/// default. Building with `--dart-define=ADMIN_WEB=false` produces a web
/// preview of the customer + shop marketplace instead.
/// Mobile/desktop builds always keep the full marketplace app.
class AppHost {
  AppHost._();

  static const _adminWebConsole = bool.fromEnvironment(
    'ADMIN_WEB',
    defaultValue: true,
  );

  /// True when running as the hosted admin web panel.
  static bool get isAdminWebConsole => kIsWeb && _adminWebConsole;

  /// True for every web build; guards renderer workarounds that are unrelated
  /// to which product the build represents.
  static bool get isWeb => kIsWeb;

  static String get publicLoginPath =>
      isAdminWebConsole ? '/staff-console' : '/auth';
}
