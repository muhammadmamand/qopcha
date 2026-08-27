import 'body_measurements.dart';

enum UserRole { customer, shopOwner, admin }

enum ApprovalStatus {
  pending,
  approved,
  rejected;

  String get labelKu => switch (this) {
        ApprovalStatus.pending => 'چاوەڕوان',
        ApprovalStatus.approved => 'پەسەندکراو',
        ApprovalStatus.rejected => 'ڕەتکراوە',
      };
}

enum ShopTier {
  silver,
  gold,
  platinum;

  String get labelKu => switch (this) {
        ShopTier.silver => 'سیلڤەر',
        ShopTier.gold => 'گۆڵد',
        ShopTier.platinum => 'پلاتینیۆم',
      };

  String get labelEn => switch (this) {
        ShopTier.silver => 'Silver',
        ShopTier.gold => 'Gold',
        ShopTier.platinum => 'Platinum',
      };

  String get subtitle => switch (this) {
        ShopTier.silver => 'دەستپێکی گونجاو بۆ دووکانی بچووک',
        ShopTier.gold => 'باشترین بۆ دووکانی گەشەسەندوو',
        ShopTier.platinum => 'پلانی تەواو بۆ فرۆشگای گەورە',
      };

  /// Longer explanation shown when the tier is selected during signup.
  String get details => switch (this) {
        ShopTier.silver =>
          'گونجاوە ئەگەر تازە دەستت پێکردووە: دووکانێکی بچووک، ژمارەیەکی سنوورداری کاڵا، و پڕۆفایلی سادە بۆ فرۆشتن.',
        ShopTier.gold =>
          'بۆ دووکانێک کە گەشە دەکات: کاڵای زیاتر، نیشاندانی تایبەت لە ئەپ، پشتگیری خێراتر، و باجی کەمتر لەسەر فرۆش.',
        ShopTier.platinum =>
          'بۆ فرۆشگای گەورە و VIP: کاڵای بێسنوور، پلەی یەکەم لە گەڕان، ڕیکلامی تایبەت، و پشتگیری ٢٤/٧.',
      };

  List<String> get benefits => switch (this) {
        ShopTier.silver => const [
            'تا ٢٠ بەرهەم دەتوانیت زیاد بکەیت',
            'پڕۆفایلی بنەڕەتی دووکان',
            'وەرگرتن و بەڕێوەبردنی داواکاری',
            'نیشاندانی دووکان لە لیستی گشتی',
          ],
        ShopTier.gold => const [
            'تا ١٠٠ بەرهەم دەتوانیت زیاد بکەیت',
            'نیشاندانی تایبەت لە پەڕەی سەرەکی',
            'پشتگیری خێراتر لە ئەدمین',
            'باجی کەمتر لەسەر فرۆش',
            'ئاماری فرۆشی باشتر',
          ],
        ShopTier.platinum => const [
            'بەرهەمی بێسنوور',
            'پلەی یەکەم لە گەڕان و پێشنیار',
            'باجەی VIP و ئۆفەری تایبەت',
            'پشتگیری ٢٤/٧',
            'ڕیکلامی تایبەت لەناو ئەپ',
            'ئاماری پێشکەوتوو بۆ فرۆش',
          ],
      };

  String get productLimitLabel => switch (this) {
        ShopTier.silver => 'سنووری کاڵا: ٢٠',
        ShopTier.gold => 'سنووری کاڵا: ١٠٠',
        ShopTier.platinum => 'سنووری کاڵا: بێسنوور',
      };

  int? get maxProducts => switch (this) {
        ShopTier.silver => 20,
        ShopTier.gold => 100,
        ShopTier.platinum => null,
      };
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final ApprovalStatus approvalStatus;
  final String? rejectionReason;
  final bool approvalNoticeSeen;
  final String? location;
  /// Customer's preferred clothing size (for example S, M, L or XL).
  final String? preferredSize;
  /// Saved body measurements used to pick the right clothing size.
  final BodyMeasurements measurements;
  /// Saved map pin (for profile map preview). Not shown as raw numbers in UI.
  final double? latitude;
  final double? longitude;
  final String? shopName;
  final String? shopDescription;
  final String? shopAddress;
  final String? avatarUrl;
  /// Public shop logo (storefront avatar / red circle).
  final String? shopLogoUrl;
  /// Public shop cover photo (storefront hero / green area).
  final String? shopCoverUrl;
  final ShopTier? shopTier;
  /// Standing % off clothing/product prices for this customer (0–100). Admin-only.
  final double productDiscountPercent;
  /// Standing % off delivery fee for this customer (0–100). Admin-only.
  final double deliveryDiscountPercent;
  final DateTime? lastNotificationsSeenAt;
  final DateTime? lastDeliveredOrdersSeenAt;
  final Map<String, DateTime> orderTabsSeenAt;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.approvalStatus = ApprovalStatus.approved,
    this.rejectionReason,
    this.approvalNoticeSeen = true,
    this.location,
    this.preferredSize,
    this.measurements = BodyMeasurements.empty,
    this.latitude,
    this.longitude,
    this.shopName,
    this.shopDescription,
    this.shopAddress,
    this.avatarUrl,
    this.shopLogoUrl,
    this.shopCoverUrl,
    this.shopTier,
    this.productDiscountPercent = 0,
    this.deliveryDiscountPercent = 0,
    this.lastNotificationsSeenAt,
    this.lastDeliveredOrdersSeenAt,
    this.orderTabsSeenAt = const {},
    required this.createdAt,
  });

  bool get hasMapPin => latitude != null && longitude != null;

  bool get isShopOwner => role == UserRole.shopOwner;
  bool get isCustomer => role == UserRole.customer;
  bool get isAdmin => role == UserRole.admin;
  bool get isApproved =>
      isAdmin || approvalStatus == ApprovalStatus.approved;
  bool get isPending =>
      !isAdmin && approvalStatus == ApprovalStatus.pending;
  bool get isRejected =>
      !isAdmin && approvalStatus == ApprovalStatus.rejected;
  bool get canPlaceOrders => isApproved;
  bool get hasUnreadApprovalNotice =>
      isApproved && !isAdmin && !approvalNoticeSeen;

  ShopTier get effectiveShopTier =>
      shopTier ?? (isShopOwner ? ShopTier.silver : ShopTier.silver);

  bool get hasSpecialDiscount =>
      productDiscountPercent > 0 || deliveryDiscountPercent > 0;

  DateTime? orderTabSeenAt(String tab) {
    final seen = orderTabsSeenAt[tab];
    if (seen != null) return seen;
    if (tab == 'delivered') return lastDeliveredOrdersSeenAt;
    return null;
  }

  /// Apply standing delivery discount to a base zone fee.
  double deliveryFeeAfterDiscount(double baseFee) {
    final d = deliveryDiscountPercent.clamp(0, 100);
    if (d <= 0) return baseFee;
    return (baseFee * (1 - d / 100)).clamp(0, double.infinity);
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    ApprovalStatus? approvalStatus,
    String? rejectionReason,
    bool clearRejectionReason = false,
    bool? approvalNoticeSeen,
    String? location,
    String? preferredSize,
    bool clearPreferredSize = false,
    BodyMeasurements? measurements,
    double? latitude,
    double? longitude,
    bool clearLocationCoords = false,
    String? shopName,
    String? shopDescription,
    String? shopAddress,
    String? avatarUrl,
    String? shopLogoUrl,
    String? shopCoverUrl,
    ShopTier? shopTier,
    double? productDiscountPercent,
    double? deliveryDiscountPercent,
    DateTime? lastNotificationsSeenAt,
    bool clearLastNotificationsSeenAt = false,
    DateTime? lastDeliveredOrdersSeenAt,
    Map<String, DateTime>? orderTabsSeenAt,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: clearRejectionReason
          ? null
          : (rejectionReason ?? this.rejectionReason),
      approvalNoticeSeen: approvalNoticeSeen ?? this.approvalNoticeSeen,
      location: location ?? this.location,
      preferredSize:
          clearPreferredSize ? null : (preferredSize ?? this.preferredSize),
      measurements: measurements ?? this.measurements,
      latitude: clearLocationCoords ? null : (latitude ?? this.latitude),
      longitude: clearLocationCoords ? null : (longitude ?? this.longitude),
      shopName: shopName ?? this.shopName,
      shopDescription: shopDescription ?? this.shopDescription,
      shopAddress: shopAddress ?? this.shopAddress,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      shopLogoUrl: shopLogoUrl ?? this.shopLogoUrl,
      shopCoverUrl: shopCoverUrl ?? this.shopCoverUrl,
      shopTier: shopTier ?? this.shopTier,
      productDiscountPercent:
          productDiscountPercent ?? this.productDiscountPercent,
      deliveryDiscountPercent:
          deliveryDiscountPercent ?? this.deliveryDiscountPercent,
      lastNotificationsSeenAt: clearLastNotificationsSeenAt
          ? null
          : (lastNotificationsSeenAt ?? this.lastNotificationsSeenAt),
      lastDeliveredOrdersSeenAt:
          lastDeliveredOrdersSeenAt ?? this.lastDeliveredOrdersSeenAt,
      orderTabsSeenAt: orderTabsSeenAt ?? this.orderTabsSeenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'approvalStatus': approvalStatus.name,
        'rejectionReason': rejectionReason,
        'approvalNoticeSeen': approvalNoticeSeen,
        'location': location,
        'preferredSize': preferredSize,
        'measurements': measurements.toJson(),
        'latitude': latitude,
        'longitude': longitude,
        'shopName': shopName,
        'shopDescription': shopDescription,
        'shopAddress': shopAddress,
        'avatarUrl': avatarUrl,
        'shopLogoUrl': shopLogoUrl,
        'shopCoverUrl': shopCoverUrl,
        'shopTier': shopTier?.name,
        'productDiscountPercent': productDiscountPercent,
        'deliveryDiscountPercent': deliveryDiscountPercent,
        'lastNotificationsSeenAt':
            lastNotificationsSeenAt?.toIso8601String(),
        'lastDeliveredOrdersSeenAt':
            lastDeliveredOrdersSeenAt?.toIso8601String(),
        'orderTabsSeenAt': {
          for (final e in orderTabsSeenAt.entries)
            e.key: e.value.toIso8601String(),
        },
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    ShopTier? tier;
    final rawTier = json['shopTier'] as String?;
    if (rawTier != null) {
      tier = ShopTier.values.cast<ShopTier?>().firstWhere(
            (t) => t!.name == rawTier,
            orElse: () => null,
          );
    }

    ApprovalStatus status = ApprovalStatus.approved;
    final rawStatus = json['approvalStatus'] as String?;
    if (rawStatus != null) {
      status = ApprovalStatus.values.firstWhere(
        (s) => s.name == rawStatus,
        orElse: () => ApprovalStatus.approved,
      );
    }

    final role = UserRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => UserRole.customer,
    );

    final reason = json['rejectionReason'] as String?;

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: (json['email'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      role: role,
      approvalStatus: role == UserRole.admin
          ? ApprovalStatus.approved
          : status,
      rejectionReason:
          reason != null && reason.trim().isNotEmpty ? reason.trim() : null,
      approvalNoticeSeen: json['approvalNoticeSeen'] as bool? ?? true,
      location: json['location'] as String?,
      preferredSize: json['preferredSize'] as String?,
      measurements: json['measurements'] is Map
          ? BodyMeasurements.fromJson(
              Map<String, dynamic>.from(json['measurements'] as Map),
            )
          : BodyMeasurements.empty,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      shopName: json['shopName'] as String?,
      shopDescription: json['shopDescription'] as String?,
      shopAddress: json['shopAddress'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      shopLogoUrl: json['shopLogoUrl'] as String?,
      shopCoverUrl: json['shopCoverUrl'] as String?,
      shopTier: tier,
      productDiscountPercent:
          (json['productDiscountPercent'] as num?)?.toDouble() ?? 0,
      deliveryDiscountPercent:
          (json['deliveryDiscountPercent'] as num?)?.toDouble() ?? 0,
      lastNotificationsSeenAt: json['lastNotificationsSeenAt'] is String
          ? DateTime.tryParse(json['lastNotificationsSeenAt'] as String)
          : null,
      lastDeliveredOrdersSeenAt: json['lastDeliveredOrdersSeenAt'] is String
          ? DateTime.tryParse(json['lastDeliveredOrdersSeenAt'] as String)
          : null,
      orderTabsSeenAt: _parseOrderTabsSeenAt(json),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static Map<String, DateTime> _parseOrderTabsSeenAt(Map<String, dynamic> json) {
    final map = <String, DateTime>{};
    final raw = json['orderTabsSeenAt'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final parsed = DateTime.tryParse('${entry.value}');
        if (parsed != null) map['${entry.key}'] = parsed;
      }
    }
    if (!map.containsKey('delivered') &&
        json['lastDeliveredOrdersSeenAt'] is String) {
      final parsed = DateTime.tryParse(
        json['lastDeliveredOrdersSeenAt'] as String,
      );
      if (parsed != null) map['delivered'] = parsed;
    }
    return map;
  }
}
