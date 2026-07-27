enum UserRole { customer, shopOwner }

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

  List<String> get benefits => switch (this) {
        ShopTier.silver => const [
            'تا ٢٠ بەرهەم',
            'پڕۆفایلی بنەڕەتی',
            'داواکارییەکان',
          ],
        ShopTier.gold => const [
            'تا ١٠٠ بەرهەم',
            'نیشاندانی تایبەت',
            'پشتگیری خێراتر',
            'باجی کەمتر',
          ],
        ShopTier.platinum => const [
            'بەرهەمی بێسنوور',
            'پلەی یەکەم لە گەڕان',
            'باجەی VIP',
            'پشتگیری ٢٤/٧',
            'ڕیکلامی تایبەت',
          ],
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
  final String? location;
  final String? shopName;
  final String? shopDescription;
  final String? shopAddress;
  final String? avatarUrl;
  final ShopTier? shopTier;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.location,
    this.shopName,
    this.shopDescription,
    this.shopAddress,
    this.avatarUrl,
    this.shopTier,
    required this.createdAt,
  });

  bool get isShopOwner => role == UserRole.shopOwner;
  bool get isCustomer => role == UserRole.customer;

  ShopTier get effectiveShopTier =>
      shopTier ?? (isShopOwner ? ShopTier.silver : ShopTier.silver);

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? location,
    String? shopName,
    String? shopDescription,
    String? shopAddress,
    String? avatarUrl,
    ShopTier? shopTier,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      location: location ?? this.location,
      shopName: shopName ?? this.shopName,
      shopDescription: shopDescription ?? this.shopDescription,
      shopAddress: shopAddress ?? this.shopAddress,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      shopTier: shopTier ?? this.shopTier,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'location': location,
        'shopName': shopName,
        'shopDescription': shopDescription,
        'shopAddress': shopAddress,
        'avatarUrl': avatarUrl,
        'shopTier': shopTier?.name,
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

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: UserRole.values.byName(json['role'] as String),
      location: json['location'] as String?,
      shopName: json['shopName'] as String?,
      shopDescription: json['shopDescription'] as String?,
      shopAddress: json['shopAddress'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      shopTier: tier,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
