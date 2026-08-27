import 'package:uuid/uuid.dart';

import '../core/constants/kurdistan_locations.dart';

class AddressModel {
  final String id;
  final String label;
  final String location;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AddressModel({
    required this.id,
    required this.label,
    required this.location,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasMapPin => latitude != null && longitude != null;

  ParsedLocation get parsed => KurdistanLocations.parse(location);

  String get city => parsed.city ?? '';
  String get neighborhood => parsed.neighborhood ?? '';
  String get details => parsed.details;

  AddressModel copyWith({
    String? id,
    String? label,
    String? location,
    double? latitude,
    double? longitude,
    bool clearCoords = false,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      location: location ?? this.location,
      latitude: clearCoords ? null : (latitude ?? this.latitude),
      longitude: clearCoords ? null : (longitude ?? this.longitude),
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? '',
      label: (json['label'] as String?)?.trim().isNotEmpty == true
          ? (json['label'] as String).trim()
          : 'ناونیشان',
      location: json['location'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory AddressModel.create({
    required String label,
    required String location,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return AddressModel(
      id: const Uuid().v4(),
      label: label.trim().isEmpty ? 'ناونیشان' : label.trim(),
      location: location.trim(),
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }
}
