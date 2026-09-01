/// Contabo VPS / local API for قۆپچە (Qopcha).
class ApiConfig {
  ApiConfig._();

  /// Override at build/run time:
  /// `flutter run --dart-define=API_BASE=http://192.168.1.4:8090`
  /// `flutter build ipa --dart-define=API_BASE=https://api.yourdomain.com`
  static const _fromEnv = String.fromEnvironment('API_BASE');

  /// Public HTTPS API (Caddy + Let's Encrypt on Contabo).
  /// Default host uses sslip.io for the VPS IP — no domain purchase needed.
  /// When you own a domain: point A-record → 169.58.230.144 and set
  /// `DOMAIN=api.yourdomain.com` on the VPS, then update this constant
  /// (or pass `--dart-define=API_BASE=https://api.yourdomain.com`).
  static const publicHttpsUrl = 'https://169-58-230-144.sslip.io';

  /// Legacy plain-HTTP VPS origin (not for App Store / release).
  static const vpsHttpUrl = 'http://169.58.230.144';

  /// Alias — always the public HTTPS origin.
  static const vpsUrl = publicHttpsUrl;

  /// This PC — emulator loopback.
  static const localUrl = 'http://127.0.0.1:8090';

  /// Android emulator → host machine.
  static const androidEmulatorUrl = 'http://10.0.2.2:8090';

  /// This PC on your home Wi‑Fi (physical phone / debug).
  static const lanUrl = 'http://192.168.1.4:8090';

  /// Always use the public Contabo HTTPS API.
  static const defaultBaseUrl = publicHttpsUrl;

  /// Public API origin (no trailing slash).
  /// - `--dart-define=API_BASE=...` overrides for local dev only
  /// - default → HTTPS Contabo (debug, profile, and release)
  static String get baseUrl {
    if (_fromEnv.isNotEmpty) {
      return _fromEnv.replaceAll(RegExp(r'/$'), '');
    }
    return defaultBaseUrl;
  }

  static const pollInterval = Duration(seconds: 8);
}
