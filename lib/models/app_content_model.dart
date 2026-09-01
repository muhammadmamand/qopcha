/// CMS document stored at `appContent/main`.
class AppContentModel {
  static const docId = 'main';
  static const collection = 'appContent';

  final String aboutBody;
  final String termsBody;
  final String privacyBody;
  final String supportPhone;
  final String supportWhatsapp;
  final String supportEmail;
  final String supportHours;
  final String socialInstagram;
  final String socialFacebook;
  final String socialTikTok;
  final String socialTelegram;
  final String homeTagline;
  final String homePromoTitle;
  final String homePromoSubtitle;
  final String homeCta;
  final DateTime updatedAt;

  const AppContentModel({
    this.aboutBody = '',
    this.termsBody = '',
    this.privacyBody = '',
    this.supportPhone = '',
    this.supportWhatsapp = '',
    this.supportEmail = '',
    this.supportHours = '',
    this.socialInstagram = '',
    this.socialFacebook = '',
    this.socialTikTok = '',
    this.socialTelegram = '',
    this.homeTagline = '',
    this.homePromoTitle = '',
    this.homePromoSubtitle = '',
    this.homeCta = '',
    required this.updatedAt,
  });

  bool get hasSocialLinks =>
      socialInstagram.trim().isNotEmpty ||
      socialFacebook.trim().isNotEmpty ||
      socialTikTok.trim().isNotEmpty ||
      socialTelegram.trim().isNotEmpty;

  static AppContentModel defaults() => AppContentModel(
        aboutBody:
            'قۆپچە بازاڕێکی جلوبەرگە — دووکان و کڕیار لە یەک ئەپدا کۆدەکاتەوە.',
        termsBody:
            'بە بەکارهێنانی ئەپەکە، ڕەزامەندیت لەسەر مەرجەکانی خزمەتگوزاری.',
        privacyBody:
            'زانیاری کەسیت تەنها بۆ کارکردنی ئەپ و گەیاندن بەکاردێت.',
        supportPhone: '',
        supportWhatsapp: '',
        supportEmail: 'qopcha07@gmail.com',
        supportHours: '٩:٠٠ — ٢١:٠٠',
        socialInstagram: '',
        socialFacebook: '',
        socialTikTok: '',
        socialTelegram: '',
        homeTagline: 'بازاڕی جلوبەرگ',
        homePromoTitle: 'داشکاندن بگرە تا',
        homePromoSubtitle: 'تەنها بۆ ماوەیەکی کەم',
        homeCta: 'ئیستا کڕین بکە',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  AppContentModel copyWith({
    String? aboutBody,
    String? termsBody,
    String? privacyBody,
    String? supportPhone,
    String? supportWhatsapp,
    String? supportEmail,
    String? supportHours,
    String? socialInstagram,
    String? socialFacebook,
    String? socialTikTok,
    String? socialTelegram,
    String? homeTagline,
    String? homePromoTitle,
    String? homePromoSubtitle,
    String? homeCta,
    DateTime? updatedAt,
  }) {
    return AppContentModel(
      aboutBody: aboutBody ?? this.aboutBody,
      termsBody: termsBody ?? this.termsBody,
      privacyBody: privacyBody ?? this.privacyBody,
      supportPhone: supportPhone ?? this.supportPhone,
      supportWhatsapp: supportWhatsapp ?? this.supportWhatsapp,
      supportEmail: supportEmail ?? this.supportEmail,
      supportHours: supportHours ?? this.supportHours,
      socialInstagram: socialInstagram ?? this.socialInstagram,
      socialFacebook: socialFacebook ?? this.socialFacebook,
      socialTikTok: socialTikTok ?? this.socialTikTok,
      socialTelegram: socialTelegram ?? this.socialTelegram,
      homeTagline: homeTagline ?? this.homeTagline,
      homePromoTitle: homePromoTitle ?? this.homePromoTitle,
      homePromoSubtitle: homePromoSubtitle ?? this.homePromoSubtitle,
      homeCta: homeCta ?? this.homeCta,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Merge Firestore values over defaults so empty fields still show fallbacks.
  AppContentModel withDefaults() {
    final d = defaults();
    String pick(String v, String fallback) =>
        v.trim().isEmpty ? fallback : v.trim();
    return AppContentModel(
      aboutBody: pick(aboutBody, d.aboutBody),
      termsBody: pick(termsBody, d.termsBody),
      privacyBody: pick(privacyBody, d.privacyBody),
      supportPhone: supportPhone.trim(),
      supportWhatsapp: supportWhatsapp.trim(),
      supportEmail: pick(supportEmail, d.supportEmail),
      supportHours: pick(supportHours, d.supportHours),
      socialInstagram: socialInstagram.trim(),
      socialFacebook: socialFacebook.trim(),
      socialTikTok: socialTikTok.trim(),
      socialTelegram: socialTelegram.trim(),
      homeTagline: pick(homeTagline, d.homeTagline),
      homePromoTitle: pick(homePromoTitle, d.homePromoTitle),
      homePromoSubtitle: pick(homePromoSubtitle, d.homePromoSubtitle),
      homeCta: pick(homeCta, d.homeCta),
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'aboutBody': aboutBody,
        'termsBody': termsBody,
        'privacyBody': privacyBody,
        'supportPhone': supportPhone,
        'supportWhatsapp': supportWhatsapp,
        'supportEmail': supportEmail,
        'supportHours': supportHours,
        'socialInstagram': socialInstagram,
        'socialFacebook': socialFacebook,
        'socialTikTok': socialTikTok,
        'socialTelegram': socialTelegram,
        'homeTagline': homeTagline,
        'homePromoTitle': homePromoTitle,
        'homePromoSubtitle': homePromoSubtitle,
        'homeCta': homeCta,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AppContentModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AppContentModel.defaults();
    return AppContentModel(
      aboutBody: (json['aboutBody'] as String?) ?? '',
      termsBody: (json['termsBody'] as String?) ?? '',
      privacyBody: (json['privacyBody'] as String?) ?? '',
      supportPhone: (json['supportPhone'] as String?) ?? '',
      supportWhatsapp: (json['supportWhatsapp'] as String?) ?? '',
      supportEmail: (json['supportEmail'] as String?) ?? '',
      supportHours: (json['supportHours'] as String?) ?? '',
      socialInstagram: (json['socialInstagram'] as String?) ?? '',
      socialFacebook: (json['socialFacebook'] as String?) ?? '',
      socialTikTok: (json['socialTikTok'] as String?) ?? '',
      socialTelegram: (json['socialTelegram'] as String?) ?? '',
      homeTagline: (json['homeTagline'] as String?) ?? '',
      homePromoTitle: (json['homePromoTitle'] as String?) ?? '',
      homePromoSubtitle: (json['homePromoSubtitle'] as String?) ?? '',
      homeCta: (json['homeCta'] as String?) ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Turns a handle or URL into an https link for [platform].
  static String? socialUrl(String raw, {required String platform}) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final handle = v.replaceFirst(RegExp(r'^@'), '');
    return switch (platform) {
      'instagram' => 'https://instagram.com/$handle',
      'facebook' => 'https://facebook.com/$handle',
      'tiktok' => 'https://www.tiktok.com/@$handle',
      'telegram' => handle.startsWith('t.me/')
          ? 'https://$handle'
          : 'https://t.me/$handle',
      _ => null,
    };
  }
}
