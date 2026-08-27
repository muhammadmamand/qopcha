import 'dart:math' show atan2, cos, sin, sqrt;

/// Kurdish cities and neighborhoods for manual address entry.
class KurdistanLocations {
  KurdistanLocations._();

  /// Cities currently served. Add more names here when the app expands.
  static const List<String> cities = [
    'هەولێر',
  ];

  static const Map<String, List<String>> neighborhoodsByCity = {
    'هەولێر': [
      'کوردستان',
      'بەختیاری',
      'نەورۆز',
      'ڕاستی',
      'دارەتوو',
      'بنەسڵاوە',
      'شۆڕش',
      'سێتاقان',
      'گەلاوێژ',
      'فەرمانبەران',
      'هاوکاری',
      'زاگرۆس',
      'ژیان',
      '٣٢ پاڕک',
      'ئیمپایەر',
      'بەحرکە',
      'عنکاوە',
      'هەولێری نوێ',
      'کوران',
      'باداوە',
      'کەسنەزان',
      'سەیداوە',
      'بێرکۆت',
      'تەیراوە',
      'کورانی عەنکاوە',
      'کوێستان',
      'پیرزین',
      'ئیسکان',
      'زیلان',
      'هەڤاڵان ڕۆشەنبیری',
      'منتکاوە',
      'شادی',
      'مامزاوە',
      'سەرکارێز',
      'بەهار',
      'مفتی',
      'زانایان',
      'برایەتی',
      'نازناز',
      'شاری خەونەکان',
      'منارە',
      'وەزیران',
      'شاری ئارام',
      'شارەوانی',
      'هەشتی حەسارۆک',
      'ئەندازیاران',
      'ڕووناکی',
      'مامۆستایانی زانکۆ',
      'ئیتاڵی ١',
      'ئیتاڵی ٢',
    ],
  };

  static List<String> neighborhoodsFor(String? city) {
    if (city == null || city.isEmpty) return const [];
    return List<String>.from(neighborhoodsByCity[city] ?? const []);
  }

  /// Approximate centers for detecting which Erbil neighborhood a pin is in.
  static const Map<String, List<double>> erbilNeighborhoodCenters = {
    'کوردستان': [36.1664, 43.9800],
    'بەختیاری': [36.2100, 43.9900],
    'نەورۆز': [36.1710, 43.9950],
    'ڕاستی': [36.1780, 43.9920],
    'دارەتوو': [36.1520, 44.0150],
    'بنەسڵاوە': [36.1180, 44.0940],
    'شۆڕش': [36.1980, 44.0250],
    'سێتاقان': [36.1600, 43.9900],
    'گەلاوێژ': [36.2150, 44.0300],
    'فەرمانبەران': [36.1920, 44.0250],
    'هاوکاری': [36.2000, 44.0080],
    'زاگرۆس': [36.1900, 44.0400],
    'ژیان': [36.2080, 44.0200],
    '٣٢ پاڕک': [36.2050, 44.0150],
    'ئیمپایەر': [36.2310, 44.0350],
    'بەحرکە': [36.2700, 44.0600],
    'عنکاوە': [36.2350, 44.0120],
    'هەولێری نوێ': [36.1650, 44.0080],
    'کوران': [36.2200, 44.0000],
    'باداوە': [36.1750, 44.0280],
    'کەسنەزان': [36.2500, 44.0400],
    'سەیداوە': [36.1600, 44.0300],
    'بێرکۆت': [36.1950, 43.9950],
    'تەیراوە': [36.1880, 44.0300],
    'کورانی عەنکاوە': [36.2450, 44.0180],
    'کوێستان': [36.2300, 44.0450],
    'پیرزین': [36.3200, 44.1500],
    'ئیسکان': [36.1780, 44.0100],
    'زیلان': [36.1750, 44.0000],
    'هەڤاڵان ڕۆشەنبیری': [36.1900, 44.0180],
    'منتکاوە': [36.2100, 44.0220],
    'شادی': [36.2000, 44.0050],
    'مامزاوە': [36.1550, 44.0400],
    'سەرکارێز': [36.1850, 44.0080],
    'بەهار': [36.1700, 43.9850],
    'مفتی': [36.1800, 44.0180],
    'زانایان': [36.1700, 44.0150],
    'برایەتی': [36.2150, 44.0150],
    'نازناز': [36.1850, 44.0400],
    'شاری خەونەکان': [36.2280, 44.0250],
    'منارە': [36.1911, 44.0092],
    'وەزیران': [36.2000, 44.0150],
    'شاری ئارام': [36.2050, 44.0280],
    'شارەوانی': [36.1900, 44.0150],
    'هەشتی حەسارۆک': [36.1980, 44.0120],
    'ئەندازیاران': [36.1880, 44.0220],
    'ڕووناکی': [36.1850, 44.0250],
    'مامۆستایانی زانکۆ': [36.1680, 44.0120],
    'ئیتاڵی ١': [36.2180, 44.0320],
    'ئیتاڵی ٢': [36.2210, 44.0360],
  };

  /// Max distance (km) to trust a neighborhood center pin.
  static const double erbilCenterMaxKm = 1.15;

  /// Nearest known Erbil neighborhood for a coordinate, or null.
  static String? nearestErbilNeighborhood(double lat, double lng) {
    final hit = nearestErbilNeighborhoodWithDistance(lat, lng);
    return hit?.name;
  }

  static ({String name, double km})? nearestErbilNeighborhoodWithDistance(
    double lat,
    double lng,
  ) {
    String? best;
    var bestKm = double.infinity;
    erbilNeighborhoodCenters.forEach((name, coords) {
      final d = _haversineKm(lat, lng, coords[0], coords[1]);
      if (d < bestKm) {
        bestKm = d;
        best = name;
      }
    });
    if (best == null || bestKm > erbilCenterMaxKm) return null;
    return (name: best!, km: bestKm);
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * 3.141592653589793 / 180.0;

  static const String separator = ' · ';

  /// Compose a single location string for storage / display.
  static String compose({
    required String city,
    required String neighborhood,
    String details = '',
    String? gps,
  }) {
    final parts = <String>[
      city.trim(),
      neighborhood.trim(),
      if (details.trim().isNotEmpty) details.trim(),
      if (gps != null && gps.trim().isNotEmpty) 'GPS: ${gps.trim()}',
    ].where((p) => p.isNotEmpty).toList();
    return parts.join(separator);
  }

  /// Parse a stored location back into city / neighborhood / details / gps.
  static ParsedLocation parse(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return const ParsedLocation();

    // Pure GPS leftover from older profiles.
    if (_looksLikeGpsOnly(text)) {
      return ParsedLocation(gps: text, details: text);
    }

    String? gps;
    var working = text;
    final gpsMatch = RegExp(r'(?:\|\s*)?GPS:\s*(.+)$', caseSensitive: false)
        .firstMatch(working);
    if (gpsMatch != null) {
      gps = gpsMatch.group(1)?.trim();
      working = working.substring(0, gpsMatch.start).trim();
      if (working.endsWith('|')) {
        working = working.substring(0, working.length - 1).trim();
      }
    }

    final parts = working
        .split(RegExp(r'\s*[·|,،]\s*'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String? city;
    String? neighborhood;
    String details = '';

    if (parts.isNotEmpty && cities.contains(parts.first)) {
      city = parts.first;
      if (parts.length >= 2) {
        final hoods = neighborhoodsFor(city);
        if (hoods.contains(parts[1]) || parts[1] == 'هیتر') {
          neighborhood = parts[1];
          if (parts.length > 2) {
            details = parts.sublist(2).join('، ');
          }
        } else {
          details = parts.sublist(1).join('، ');
        }
      }
    } else {
      details = working;
    }

    return ParsedLocation(
      city: city,
      neighborhood: neighborhood,
      details: details,
      gps: gps,
    );
  }

  static bool _looksLikeGpsOnly(String text) {
    return RegExp(
      r'^-?\d+\.\d+\s*,\s*-?\d+\.\d+$',
    ).hasMatch(text.trim());
  }
}

class ParsedLocation {
  final String? city;
  final String? neighborhood;
  final String details;
  final String? gps;

  const ParsedLocation({
    this.city,
    this.neighborhood,
    this.details = '',
    this.gps,
  });
}
