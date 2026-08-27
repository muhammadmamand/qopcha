import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps (browser / app) for a pin or address.
/// Works on Android, iOS, and Flutter Web (admin Chrome).
class MapsLauncherService {
  const MapsLauncherService();

  Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) {
    return openDirections(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
  }

  /// Prefer coordinates; fall back to free-text address search.
  Future<bool> openDirections({
    double? latitude,
    double? longitude,
    String? address,
    String? label,
  }) async {
    final hasPin = latitude != null && longitude != null;
    final query = (address ?? label ?? '').trim();
    if (!hasPin && query.isEmpty) return false;

    final uri = hasPin
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
          )
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
          );

    // Web: open a new tab. Mobile: hand off to Maps / browser.
    return launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );
  }
}
