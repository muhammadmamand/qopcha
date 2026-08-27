/// Body measurements a customer saves so clothing sizes fit correctly.
///
/// Lengths are centimetres, weight is kilograms, shoe size is EU.
class BodyMeasurements {
  final double? heightCm;
  final double? weightKg;
  final double? shoulderCm;
  final double? chestCm;
  final double? waistCm;
  final double? hipCm;
  final double? armLengthCm;
  final double? legLengthCm;
  final double? neckCm;
  final double? shoeSizeEu;
  final DateTime? updatedAt;

  const BodyMeasurements({
    this.heightCm,
    this.weightKg,
    this.shoulderCm,
    this.chestCm,
    this.waistCm,
    this.hipCm,
    this.armLengthCm,
    this.legLengthCm,
    this.neckCm,
    this.shoeSizeEu,
    this.updatedAt,
  });

  static const empty = BodyMeasurements();

  List<double?> get _all => [
        heightCm,
        weightKg,
        shoulderCm,
        chestCm,
        waistCm,
        hipCm,
        armLengthCm,
        legLengthCm,
        neckCm,
        shoeSizeEu,
      ];

  bool get isEmpty => _all.every((v) => v == null);
  bool get isNotEmpty => !isEmpty;

  int get filledCount => _all.where((v) => v != null).length;
  int get totalCount => _all.length;

  /// 0–1 progress used by the measurements page header.
  double get completion => filledCount / totalCount;

  /// Body mass index, when both height and weight are known.
  double? get bmi {
    final h = heightCm;
    final w = weightKg;
    if (h == null || w == null || h <= 0) return null;
    final meters = h / 100;
    return w / (meters * meters);
  }

  /// Letter size suggestion derived from chest, then waist, then weight.
  String? get suggestedSize {
    final chest = chestCm;
    if (chest != null) {
      if (chest < 86) return 'XS';
      if (chest < 94) return 'S';
      if (chest < 102) return 'M';
      if (chest < 110) return 'L';
      if (chest < 118) return 'XL';
      return 'XXL';
    }

    final waist = waistCm;
    if (waist != null) {
      if (waist < 70) return 'XS';
      if (waist < 78) return 'S';
      if (waist < 86) return 'M';
      if (waist < 94) return 'L';
      if (waist < 102) return 'XL';
      return 'XXL';
    }

    final weight = weightKg;
    if (weight != null) {
      if (weight < 55) return 'XS';
      if (weight < 65) return 'S';
      if (weight < 75) return 'M';
      if (weight < 88) return 'L';
      if (weight < 100) return 'XL';
      return 'XXL';
    }

    return null;
  }

  BodyMeasurements copyWith({
    double? heightCm,
    double? weightKg,
    double? shoulderCm,
    double? chestCm,
    double? waistCm,
    double? hipCm,
    double? armLengthCm,
    double? legLengthCm,
    double? neckCm,
    double? shoeSizeEu,
    DateTime? updatedAt,
  }) {
    return BodyMeasurements(
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      shoulderCm: shoulderCm ?? this.shoulderCm,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      hipCm: hipCm ?? this.hipCm,
      armLengthCm: armLengthCm ?? this.armLengthCm,
      legLengthCm: legLengthCm ?? this.legLengthCm,
      neckCm: neckCm ?? this.neckCm,
      shoeSizeEu: shoeSizeEu ?? this.shoeSizeEu,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'heightCm': heightCm,
        'weightKg': weightKg,
        'shoulderCm': shoulderCm,
        'chestCm': chestCm,
        'waistCm': waistCm,
        'hipCm': hipCm,
        'armLengthCm': armLengthCm,
        'legLengthCm': legLengthCm,
        'neckCm': neckCm,
        'shoeSizeEu': shoeSizeEu,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory BodyMeasurements.fromJson(Map<String, dynamic> json) {
    double? read(String key) => (json[key] as num?)?.toDouble();
    final raw = json['updatedAt'];
    return BodyMeasurements(
      heightCm: read('heightCm'),
      weightKg: read('weightKg'),
      shoulderCm: read('shoulderCm'),
      chestCm: read('chestCm'),
      waistCm: read('waistCm'),
      hipCm: read('hipCm'),
      armLengthCm: read('armLengthCm'),
      legLengthCm: read('legLengthCm'),
      neckCm: read('neckCm'),
      shoeSizeEu: read('shoeSizeEu'),
      updatedAt: raw is String ? DateTime.tryParse(raw) : null,
    );
  }
}
