class BannerModel {
  /// Target export size so the home slider is filled edge-to-edge.
  /// Matches [sliderHeight] at a typical phone width (~390dp).
  static const int recommendedWidthPx = 1080;
  static const int recommendedHeightPx = 980;
  static const double sliderHeight = 340;
  static const double aspectRatio =
      recommendedWidthPx / recommendedHeightPx; // ≈ 1.10

  final String id;
  final String title;
  final String highlight;
  final String subtitle;
  final String cta;
  final String tag;
  final String imageUrl;
  final bool active;
  final int order;
  final DateTime createdAt;

  const BannerModel({
    required this.id,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.cta,
    required this.tag,
    required this.imageUrl,
    this.active = true,
    this.order = 0,
    required this.createdAt,
  });

  BannerModel copyWith({
    String? id,
    String? title,
    String? highlight,
    String? subtitle,
    String? cta,
    String? tag,
    String? imageUrl,
    bool? active,
    int? order,
    DateTime? createdAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      highlight: highlight ?? this.highlight,
      subtitle: subtitle ?? this.subtitle,
      cta: cta ?? this.cta,
      tag: tag ?? this.tag,
      imageUrl: imageUrl ?? this.imageUrl,
      active: active ?? this.active,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'highlight': highlight,
        'subtitle': subtitle,
        'cta': cta,
        'tag': tag,
        'imageUrl': imageUrl,
        'active': active,
        'order': order,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BannerModel.fromJson(String id, Map<String, dynamic> json) {
    return BannerModel(
      id: id,
      title: (json['title'] as String?) ?? '',
      highlight: (json['highlight'] as String?) ?? '',
      subtitle: (json['subtitle'] as String?) ?? '',
      cta: (json['cta'] as String?) ?? 'بینین',
      tag: (json['tag'] as String?) ?? 'AD',
      imageUrl: (json['imageUrl'] as String?) ?? '',
      active: (json['active'] as bool?) ?? true,
      order: (json['order'] as int?) ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
