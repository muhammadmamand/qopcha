import 'dart:convert';
import 'dart:math' show atan2, cos, sin, sqrt;

import 'package:http/http.dart' as http;

import '../core/constants/kurdistan_locations.dart';

class NearbyPlace {
  final String name;
  final String typeLabel;
  final double distanceMeters;

  const NearbyPlace({
    required this.name,
    required this.typeLabel,
    required this.distanceMeters,
  });

  String get label {
    final meters = distanceMeters.round();
    final dist = meters < 1000
        ? '$meters م'
        : '${(meters / 1000).toStringAsFixed(1)} کم';
    return '$typeLabel · $name ($dist)';
  }
}

class ResolvedPlace {
  final String? city;
  final String? neighborhood;
  final String nearest;
  final String summary;
  final double latitude;
  final double longitude;
  final List<NearbyPlace> nearby;

  const ResolvedPlace({
    this.city,
    this.neighborhood,
    required this.nearest,
    required this.summary,
    required this.latitude,
    required this.longitude,
    this.nearby = const [],
  });
}

/// Turns GPS coordinates into city / neighborhood / nearby landmarks.
class ReverseGeocodeService {
  ReverseGeocodeService._();
  static final ReverseGeocodeService instance = ReverseGeocodeService._();

  static const _nominatim = 'https://nominatim.openstreetmap.org/reverse';
  static const _overpass = 'https://overpass-api.de/api/interpreter';

  static const Map<String, String> _cityAliases = {
    'erbil': 'هەولێر',
    'irbil': 'هەولێر',
    'hawler': 'هەولێر',
    'arbil': 'هەولێر',
    'أربيل': 'هەولێر',
    'هەولێر': 'هەولێر',
    'هولير': 'هەولێر',
    'sulaymaniyah': 'سلێمانی',
    'sulaimaniya': 'سلێمانی',
    'sulaimani': 'سلێمانی',
    'slemani': 'سلێمانی',
    'as-sulaymaniyah': 'سلێمانی',
    'السليمانية': 'سلێمانی',
    'سلێمانی': 'سلێمانی',
    'dohuk': 'دهۆک',
    'duhok': 'دهۆک',
    'dahuk': 'دهۆک',
    'دهوك': 'دهۆک',
    'دهۆک': 'دهۆک',
    'kirkuk': 'کەرکوک',
    'karkuk': 'کەرکوک',
    'كركوك': 'کەرکوک',
    'کەرکوک': 'کەرکوک',
    'halabja': 'هەڵەبجە',
    'halabjah': 'هەڵەبجە',
    'حلبجة': 'هەڵەبجە',
    'هەڵەبجە': 'هەڵەبجە',
    'zakho': 'زاخۆ',
    'zaxo': 'زاخۆ',
    'زاخو': 'زاخۆ',
    'زاخۆ': 'زاخۆ',
    'koya': 'کۆیە',
    'koysinjaq': 'کۆیە',
    'کۆیە': 'کۆیە',
    'ranya': 'ڕانیە',
    'raniye': 'ڕانیە',
    'ڕانیە': 'ڕانیە',
    'chamchamal': 'چەمچەماڵ',
    'chammchamal': 'چەمچەماڵ',
    'چەمچەماڵ': 'چەمچەماڵ',
    'soran': 'سۆران',
    'سۆران': 'سۆران',
    'ئاكرێ': 'ئاكرێ',
    'ئاکرێ': 'ئاكرێ',
    'akre': 'ئاكرێ',
    'aqrah': 'ئاكرێ',
    'shaqlawa': 'شەقڵاوە',
    'شەقڵاوە': 'شەقڵاوە',
  };

  static const Map<String, String> _neighborhoodAliases = {
    'ankawa': 'عنکاوە',
    'ainkawa': 'عنکاوە',
    'enkawa': 'عنکاوە',
    'عنكاوا': 'عنکاوە',
    'انکاوا': 'عنکاوە',
    'عینکاوا': 'عنکاوە',
    'عنکاوە': 'عنکاوە',
    'new ankawa': 'کورانی عەنکاوە',
    'ئەنکاوەی نوێ': 'کورانی عەنکاوە',
    'shorsh': 'شۆڕش',
    'shoresh': 'شۆڕش',
    'شۆڕش': 'شۆڕش',
    'bakhtiari': 'بەختیاری',
    'بەختیاری': 'بەختیاری',
    'nawroz': 'نەورۆز',
    'newroz': 'نەورۆز',
    'نەورۆز': 'نەورۆز',
    'kasnazan': 'کەسنەزان',
    'کەسنەزان': 'کەسنەزان',
    'daratoo': 'دارەتوو',
    'daratu': 'دارەتوو',
    'دارەتوو': 'دارەتوو',
    'italian village': 'ئیتاڵی ١',
    'italian village 1': 'ئیتاڵی ١',
    'italian village 2': 'ئیتاڵی ٢',
    'ڤیلەی ئیتاڵی': 'ئیتاڵی ١',
    'ئیتاڵی ١': 'ئیتاڵی ١',
    'ئیتاڵی ٢': 'ئیتاڵی ٢',
    'galavezh': 'گەلاوێژ',
    'گەڵاویژ': 'گەلاوێژ',
    'گەلاوێژ': 'گەلاوێژ',
    'baharka': 'بەحرکە',
    'بەحرکە': 'بەحرکە',
    'kurdistan': 'کوردستان',
    'kurdistan quarter': 'کوردستان',
    'kurdistan neighborhood': 'کوردستان',
    'hayy kurdistan': 'کوردستان',
    'حي كردستان': 'کوردستان',
    'حی کوردستان': 'کوردستان',
    'کوردستان': 'کوردستان',
    'گەڕەکی کوردستان': 'کوردستان',
    'bahar': 'بەهار',
    'بهار': 'بەهار',
    'بەهار': 'بەهار',
    'rasti': 'ڕاستی',
    'ڕاستی': 'ڕاستی',
    'brayati': 'برایەتی',
    'برایتی': 'برایەتی',
    'برایەتی': 'برایەتی',
    'runaki': 'ڕووناکی',
    'روناکی': 'ڕووناکی',
    'ڕووناکی': 'ڕووناکی',
    'badawa': 'باداوە',
    'باداوا': 'باداوە',
    'باداوە': 'باداوە',
    'iskan': 'ئیسکان',
    'iskan district': 'ئیسکان',
    'ئەسکەن': 'ئیسکان',
    'ئیسکان': 'ئیسکان',
    'mufti': 'مفتی',
    'موفتی': 'مفتی',
    'مفتی': 'مفتی',
    'tayrawa': 'تەیراوە',
    'تەیراوا': 'تەیراوە',
    'تەیراوە': 'تەیراوە',
    'binaslawa': 'بنەسڵاوە',
    'بنەسڵاوە': 'بنەسڵاوە',
    'بەسراوە': 'بنەسڵاوە',
    'empire': 'ئیمپایەر',
    'empire world': 'ئیمپایەر',
    'ئیمپایەر': 'ئیمپایەر',
    'dream city': 'شاری خەونەکان',
    'شاری خەونەکان': 'شاری خەونەکان',
    'new erbil': 'هەولێری نوێ',
    'هەولێری نوێ': 'هەولێری نوێ',
    '32 park': '٣٢ پاڕک',
    'park 32': '٣٢ پاڕک',
    '٣٢ پاڕک': '٣٢ پاڕک',
    'naznaz': 'نازناز',
    'نازناز': 'نازناز',
    'zanko': 'مامۆستایانی زانکۆ',
    'university teachers': 'مامۆستایانی زانکۆ',
    'مامۆستایان': 'مامۆستایانی زانکۆ',
    'مامۆستایانی زانکۆ': 'مامۆستایانی زانکۆ',
    'saidawa': 'سەیداوە',
    'سەیداوە': 'سەیداوە',
    'mentkawa': 'منتکاوە',
    'مەنتیکاوا': 'منتکاوە',
    'منتکاوە': 'منتکاوە',
  };

  Future<ResolvedPlace> resolve(double latitude, double longitude) async {
    final nominatimFuture = _reverseNominatim(latitude, longitude);
    final nearbyFuture = _nearbyPlaces(latitude, longitude);

    final addressBundle = await nominatimFuture;
    final nearby = await nearbyFuture;

    var city = addressBundle.city;
    // If still unknown, guess Erbil from coordinate bounds.
    city ??= _cityFromBounds(latitude, longitude);

    var neighborhood = addressBundle.neighborhood;
    if (city == 'هەولێر') {
      neighborhood = _resolveErbilNeighborhood(
        osmName: neighborhood,
        lat: latitude,
        lng: longitude,
        displayName: addressBundle.displayName,
      );
    } else if (neighborhood == null && city != null) {
      final hoods = KurdistanLocations.neighborhoodsFor(city);
      if (hoods.contains('ناو شار')) neighborhood = 'ناو شار';
    }

    final nearest = nearby.isNotEmpty
        ? 'نزیک ${nearby.first.typeLabel}: ${nearby.first.name}'
        : addressBundle.roadHint;

    final parts = <String>[
      if (city != null) city,
      if (neighborhood != null) neighborhood,
      if (nearest.isNotEmpty) nearest,
    ];

    return ResolvedPlace(
      city: city,
      neighborhood: neighborhood,
      nearest: nearest,
      summary: parts.join(KurdistanLocations.separator),
      latitude: latitude,
      longitude: longitude,
      nearby: nearby,
    );
  }

  Future<
      ({
        String? city,
        String? neighborhood,
        String roadHint,
        String displayName,
      })> _reverseNominatim(double latitude, double longitude) async {
    final uri = Uri.parse(_nominatim).replace(queryParameters: {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'jsonv2',
      'addressdetails': '1',
      'namedetails': '1',
      'zoom': '18',
      'accept-language': 'ckb,ku,ar,en',
    });

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'QopchaApp/1.0 (shik-posh; contact@qopcha.app)',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      return (
        city: null,
        neighborhood: null,
        roadHint: '',
        displayName: '',
      );
    }

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      return (
        city: null,
        neighborhood: null,
        roadHint: '',
        displayName: '',
      );
    }

    final address = (json['address'] as Map?)?.cast<String, dynamic>() ?? {};
    final displayName = (json['display_name'] as String?)?.trim() ?? '';
    final namedetails =
        (json['namedetails'] as Map?)?.cast<String, dynamic>() ?? {};
    final city = _matchCity(address);
    final neighborhood = _matchNeighborhood(
      address,
      city,
      displayName: displayName,
      namedetails: namedetails,
    );
    final roadHint = _roadHint(address, displayName);
    return (
      city: city,
      neighborhood: neighborhood,
      roadHint: roadHint,
      displayName: displayName,
    );
  }

  /// OSM name first; tight geo-center only as fallback / confirmation.
  String? _resolveErbilNeighborhood({
    required String? osmName,
    required double lat,
    required double lng,
    required String displayName,
  }) {
    final hoods = KurdistanLocations.neighborhoodsFor('هەولێر');
    final fromDisplay = _matchTextToNeighborhood(displayName, 'هەولێر');
    var osm = osmName ?? fromDisplay;
    if (osm != null && !hoods.contains(osm)) osm = null;
    final geo =
        KurdistanLocations.nearestErbilNeighborhoodWithDistance(lat, lng);

    if (osm != null) {
      if (geo == null) return osm;
      if (geo.name == osm) return osm;
      return osm;
    }

    return geo?.name;
  }

  Future<List<NearbyPlace>> _nearbyPlaces(
    double latitude,
    double longitude,
  ) async {
    const radius = 900;
    final query = '''
[out:json][timeout:20];
(
  node["amenity"="place_of_worship"](around:$radius,$latitude,$longitude);
  node["amenity"="mosque"](around:$radius,$latitude,$longitude);
  node["amenity"="school"](around:$radius,$latitude,$longitude);
  node["amenity"="hospital"](around:$radius,$latitude,$longitude);
  node["amenity"="clinic"](around:$radius,$latitude,$longitude);
  node["amenity"="university"](around:$radius,$latitude,$longitude);
  node["amenity"="pharmacy"](around:$radius,$latitude,$longitude);
  node["amenity"="marketplace"](around:$radius,$latitude,$longitude);
  node["amenity"="fuel"](around:$radius,$latitude,$longitude);
  node["amenity"="bank"](around:$radius,$latitude,$longitude);
  node["shop"="supermarket"](around:$radius,$latitude,$longitude);
  node["leisure"="park"](around:$radius,$latitude,$longitude);
  way["amenity"="place_of_worship"](around:$radius,$latitude,$longitude);
  way["amenity"="school"](around:$radius,$latitude,$longitude);
  way["amenity"="hospital"](around:$radius,$latitude,$longitude);
  way["amenity"="clinic"](around:$radius,$latitude,$longitude);
  way["leisure"="park"](around:$radius,$latitude,$longitude);
);
out center 20;
''';

    try {
      final response = await http.post(
        Uri.parse(_overpass),
        headers: const {
          'User-Agent': 'QopchaApp/1.0 (shik-posh; contact@qopcha.app)',
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 22));

      if (response.statusCode != 200) return const [];

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return const [];
      final elements = json['elements'];
      if (elements is! List) return const [];

      final places = <NearbyPlace>[];
      for (final el in elements) {
        if (el is! Map) continue;
        final tags = (el['tags'] as Map?)?.cast<String, dynamic>() ?? {};
        final name = (tags['name:ckb'] ??
                tags['name:ku'] ??
                tags['name:ar'] ??
                tags['name'] ??
                '')
            .toString()
            .trim();
        if (name.isEmpty) continue;

        final lat = (el['lat'] as num?)?.toDouble() ??
            (el['center'] is Map
                ? (el['center']['lat'] as num?)?.toDouble()
                : null);
        final lon = (el['lon'] as num?)?.toDouble() ??
            (el['center'] is Map
                ? (el['center']['lon'] as num?)?.toDouble()
                : null);
        if (lat == null || lon == null) continue;

        final typeLabel = _poiTypeLabel(tags);
        if (typeLabel == null) continue;

        final meters =
            _haversineKm(latitude, longitude, lat, lon) * 1000;
        places.add(
          NearbyPlace(
            name: name,
            typeLabel: typeLabel,
            distanceMeters: meters,
          ),
        );
      }

      places.sort(
        (a, b) => a.distanceMeters.compareTo(b.distanceMeters),
      );

      // Keep diverse types: first of each type, then fill.
      final picked = <NearbyPlace>[];
      final seenTypes = <String>{};
      for (final p in places) {
        if (seenTypes.add(p.typeLabel)) picked.add(p);
        if (picked.length >= 4) break;
      }
      for (final p in places) {
        if (picked.length >= 4) break;
        if (!picked.contains(p)) picked.add(p);
      }
      return picked;
    } catch (_) {
      return const [];
    }
  }

  String? _poiTypeLabel(Map<String, dynamic> tags) {
    final amenity = (tags['amenity'] ?? '').toString();
    final shop = (tags['shop'] ?? '').toString();
    final leisure = (tags['leisure'] ?? '').toString();
    final religion = (tags['religion'] ?? '').toString();

    if (amenity == 'place_of_worship' || amenity == 'mosque') {
      if (religion == 'muslim' || religion.isEmpty || amenity == 'mosque') {
        return 'مزگەوت';
      }
      return 'شوێنی پەرستن';
    }
    if (amenity == 'school') return 'قوتابخانە';
    if (amenity == 'hospital') return 'نەخۆشخانە';
    if (amenity == 'clinic') return 'کلینیک';
    if (amenity == 'university') return 'زانکۆ';
    if (amenity == 'pharmacy') return 'دەرمانخانە';
    if (amenity == 'marketplace' || shop == 'supermarket') return 'بازاڕ';
    if (amenity == 'fuel') return 'بەنزینخانە';
    if (amenity == 'bank') return 'بانک';
    if (leisure == 'park') return 'پارک';
    return null;
  }

  String? _cityFromBounds(double lat, double lng) {
    // Rough bounding boxes for KRI cities.
    if (lat > 36.05 && lat < 36.45 && lng > 43.85 && lng < 44.35) {
      return 'هەولێر';
    }
    if (lat > 35.45 && lat < 35.70 && lng > 45.25 && lng < 45.60) {
      return 'سلێمانی';
    }
    if (lat > 36.80 && lat < 37.10 && lng > 42.90 && lng < 43.20) {
      return 'دهۆک';
    }
    if (lat > 35.35 && lat < 35.55 && lng > 44.25 && lng < 44.50) {
      return 'کەرکوک';
    }
    return null;
  }

  String? _matchCity(Map<String, dynamic> address) {
    final candidates = [
      address['city'],
      address['town'],
      address['municipality'],
      address['county'],
      address['state_district'],
      address['village'],
      address['province'],
      address['state'],
    ];

    for (final raw in candidates) {
      final mapped = _aliasLookup(raw?.toString(), _cityAliases);
      if (mapped != null && KurdistanLocations.cities.contains(mapped)) {
        return mapped;
      }
      final direct = raw?.toString().trim();
      if (direct != null && KurdistanLocations.cities.contains(direct)) {
        return direct;
      }
    }

    for (final value in address.values) {
      final mapped = _aliasLookup(value?.toString(), _cityAliases);
      if (mapped != null && KurdistanLocations.cities.contains(mapped)) {
        return mapped;
      }
    }
    return null;
  }

  String? _matchNeighborhood(
    Map<String, dynamic> address,
    String? city, {
    String displayName = '',
    Map<String, dynamic> namedetails = const {},
  }) {
    final candidates = <String>[
      address['suburb']?.toString() ?? '',
      address['neighbourhood']?.toString() ?? '',
      address['neighborhood']?.toString() ?? '',
      address['quarter']?.toString() ?? '',
      address['city_district']?.toString() ?? '',
      address['district']?.toString() ?? '',
      address['residential']?.toString() ?? '',
      address['hamlet']?.toString() ?? '',
      address['suburb']?.toString() ?? '',
      namedetails['name:ckb']?.toString() ?? '',
      namedetails['name:ku']?.toString() ?? '',
      namedetails['name:ar']?.toString() ?? '',
      namedetails['name']?.toString() ?? '',
      // Also scan display_name segments (often includes quarter).
      ...displayName.split(',').map((e) => e.trim()),
    ];

    for (final text in candidates) {
      final hit = _matchTextToNeighborhood(text, city);
      if (hit != null) return hit;
    }
    return null;
  }

  String? _matchTextToNeighborhood(String? raw, String? city) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    // Avoid matching the whole Kurdistan Region as the SW08 quarter.
    final lowerAll = text.toLowerCase();
    if (lowerAll.contains('region') ||
        lowerAll.contains('governorate') ||
        lowerAll.contains('province') ||
        text.contains('هەرێم') ||
        text.contains('پارێزگا') ||
        text.contains('محافظة')) {
      return null;
    }
    final hoods = KurdistanLocations.neighborhoodsFor(city);

    final aliased = _aliasLookup(text, _neighborhoodAliases);
    if (aliased != null && (hoods.isEmpty || hoods.contains(aliased))) {
      return aliased;
    }
    if (hoods.contains(text)) return text;

    final lower = text.toLowerCase();
    // Prefer longer neighborhood names first (کوردستان before کورد).
    final sortedHoods = [...hoods]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final hood in sortedHoods) {
      if (hood == 'هیتر' || hood == 'ناو شار') continue;
      if (lower.contains(hood.toLowerCase()) ||
          hood.contains(text) ||
          lower.contains(hood)) {
        return hood;
      }
    }

    final aliasEntries = _neighborhoodAliases.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in aliasEntries) {
      if (lower.contains(entry.key) &&
          (hoods.isEmpty || hoods.contains(entry.value))) {
        return entry.value;
      }
    }
    return null;
  }

  String _roadHint(Map<String, dynamic> address, String displayName) {
    final road = (address['road'] ?? address['pedestrian'] ?? '')
        .toString()
        .trim();
    if (road.isNotEmpty) return 'نزیک شەقامی $road';
    if (displayName.isNotEmpty) {
      final first = displayName.split(',').first.trim();
      if (first.isNotEmpty) return 'نزیک $first';
    }
    return '';
  }

  String? _aliasLookup(String? raw, Map<String, String> aliases) {
    if (raw == null) return null;
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    final lower = cleaned.toLowerCase();
    if (aliases.containsKey(lower)) return aliases[lower];
    if (aliases.containsKey(cleaned)) return aliases[cleaned];
    for (final entry in aliases.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }
    return null;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_rad(lat1)) *
            cos(_rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * r * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * 3.141592653589793 / 180.0;
}
