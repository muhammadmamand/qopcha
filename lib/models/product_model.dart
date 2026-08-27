class SizeStock {
  final String size;
  final int quantity;

  const SizeStock({required this.size, required this.quantity});

  Map<String, dynamic> toJson() => {'size': size, 'quantity': quantity};

  factory SizeStock.fromJson(Map<String, dynamic> json) => SizeStock(
        size: json['size'] as String,
        quantity: json['quantity'] as int,
      );

  SizeStock copyWith({String? size, int? quantity}) => SizeStock(
        size: size ?? this.size,
        quantity: quantity ?? this.quantity,
      );
}

class ProductKind {
  static const clothing = 'clothing';
  static const fabric = 'fabric';
}

class DiscountKind {
  static const percent = 'percent';
  static const amount = 'amount';
}

class ProductModel {
  final String id;
  final String shopOwnerId;
  final String shopName;
  final String name;
  final String description;
  final String category;
  final double price;
  final List<String> colors;
  final String material;
  final String brand;
  final List<String> imageUrls;
  final List<SizeStock> sizeStocks;
  /// `clothing` (default) or `fabric`. Missing on old docs → clothing.
  final String productType;
  final String fabricType;
  final String fabricQuality;
  final double fabricWidthCm;
  final int fabricWeightGsm;
  final String fabricPattern;
  final String fabricOrigin;
  final String fabricCare;
  final bool isFeatured;
  /// 0–100. Used when [discountType] is percent.
  final double discountPercent;
  /// IQD taken off [price]. Used when [discountType] is amount.
  final double discountAmount;
  /// [DiscountKind.percent] or [DiscountKind.amount].
  final String discountType;
  /// When true, [discountPercent] applies to every customer.
  final bool discountForAllCustomers;
  /// Used when [discountForAllCustomers] is false.
  final List<String> discountCustomerIds;
  /// `shop` | `admin` | empty. Who last set the product discount.
  final String discountSetBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.shopOwnerId,
    required this.shopName,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.colors,
    required this.material,
    required this.brand,
    required this.imageUrls,
    required this.sizeStocks,
    this.productType = ProductKind.clothing,
    this.fabricType = '',
    this.fabricQuality = '',
    this.fabricWidthCm = 0,
    this.fabricWeightGsm = 0,
    this.fabricPattern = '',
    this.fabricOrigin = '',
    this.fabricCare = '',
    this.isFeatured = false,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.discountType = DiscountKind.percent,
    this.discountForAllCustomers = true,
    this.discountCustomerIds = const [],
    this.discountSetBy = '',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFabric => productType == ProductKind.fabric;

  bool get isClothing => !isFabric;

  /// Display string for UI (joined colors).
  String get color => colors.isEmpty ? '' : colors.join('، ');

  int get totalStock => sizeStocks.fold(0, (sum, s) => sum + s.quantity);

  bool get inStock => totalStock > 0;

  bool get isAmountDiscount =>
      discountType == DiscountKind.amount && discountAmount > 0;

  bool get hasDiscount =>
      discountPercent > 0 || isAmountDiscount;

  /// Whether this product has any configured discount (admin/shop view).
  bool get hasConfiguredDiscount => hasDiscount;

  bool get isShopSetDiscount =>
      hasConfiguredDiscount && discountSetBy == 'shop';

  double get _amountSalePrice {
    final sale = price - discountAmount;
    if (sale < 0) return 0;
    if (sale > price) return price;
    return sale;
  }

  /// Sale price ignoring audience (for shop/admin management UI).
  double get configuredSalePrice {
    if (isAmountDiscount) return _amountSalePrice;
    if (discountPercent <= 0) return price;
    return price * (1 - discountPercent.clamp(0, 100) / 100);
  }

  /// Percent equivalent of the configured product discount (for VIP compare).
  double get equivalentDiscountPercent {
    if (price <= 0) return 0;
    if (isAmountDiscount) {
      return ((discountAmount / price) * 100).clamp(0, 100).toDouble();
    }
    return discountPercent.clamp(0, 100).toDouble();
  }

  String get discountBadgeLabel {
    if (isAmountDiscount) {
      return '-${discountAmount.round()} IQD';
    }
    if (discountPercent > 0) {
      return '${discountPercent.round()}٪-';
    }
    return '';
  }

  /// Product-level discount for [customerId] (ignores personal VIP %).
  double productDiscountPercentFor(String? customerId) {
    if (!hasConfiguredDiscount) return 0;
    if (!discountForAllCustomers) {
      if (customerId == null || customerId.isEmpty) return 0;
      if (!discountCustomerIds.contains(customerId)) return 0;
    }
    return equivalentDiscountPercent;
  }

  /// Effective discount: better of product targeting and personal standing %.
  double discountPercentFor(
    String? customerId, {
    double personalDiscountPercent = 0,
  }) {
    final productD = productDiscountPercentFor(customerId);
    final personal = personalDiscountPercent.clamp(0, 100).toDouble();
    return productD >= personal ? productD : personal;
  }

  bool hasDiscountFor(
    String? customerId, {
    double personalDiscountPercent = 0,
  }) =>
      discountPercentFor(
        customerId,
        personalDiscountPercent: personalDiscountPercent,
      ) >
      0;

  double salePriceFor(
    String? customerId, {
    double personalDiscountPercent = 0,
  }) {
    var productSale = price;
    if (productDiscountPercentFor(customerId) > 0) {
      productSale = configuredSalePrice;
    }
    final personal = personalDiscountPercent.clamp(0, 100).toDouble();
    final personalSale =
        personal > 0 ? price * (1 - personal / 100) : price;
    final sale = productSale < personalSale ? productSale : personalSale;
    if (sale < 0) return 0;
    if (sale > price) return price;
    return sale;
  }

  double get salePrice => salePriceFor(null);

  List<String> get availableSizes =>
      sizeStocks.where((s) => s.quantity > 0).map((s) => s.size).toList();

  ProductModel copyWith({
    String? id,
    String? shopOwnerId,
    String? shopName,
    String? name,
    String? description,
    String? category,
    double? price,
    List<String>? colors,
    String? material,
    String? brand,
    List<String>? imageUrls,
    List<SizeStock>? sizeStocks,
    String? productType,
    String? fabricType,
    String? fabricQuality,
    double? fabricWidthCm,
    int? fabricWeightGsm,
    String? fabricPattern,
    String? fabricOrigin,
    String? fabricCare,
    bool? isFeatured,
    double? discountPercent,
    double? discountAmount,
    String? discountType,
    bool? discountForAllCustomers,
    List<String>? discountCustomerIds,
    String? discountSetBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      shopOwnerId: shopOwnerId ?? this.shopOwnerId,
      shopName: shopName ?? this.shopName,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      colors: colors ?? this.colors,
      material: material ?? this.material,
      brand: brand ?? this.brand,
      imageUrls: imageUrls ?? this.imageUrls,
      sizeStocks: sizeStocks ?? this.sizeStocks,
      productType: productType ?? this.productType,
      fabricType: fabricType ?? this.fabricType,
      fabricQuality: fabricQuality ?? this.fabricQuality,
      fabricWidthCm: fabricWidthCm ?? this.fabricWidthCm,
      fabricWeightGsm: fabricWeightGsm ?? this.fabricWeightGsm,
      fabricPattern: fabricPattern ?? this.fabricPattern,
      fabricOrigin: fabricOrigin ?? this.fabricOrigin,
      fabricCare: fabricCare ?? this.fabricCare,
      isFeatured: isFeatured ?? this.isFeatured,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      discountForAllCustomers:
          discountForAllCustomers ?? this.discountForAllCustomers,
      discountCustomerIds: discountCustomerIds ?? this.discountCustomerIds,
      discountSetBy: discountSetBy ?? this.discountSetBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopOwnerId': shopOwnerId,
        'shopName': shopName,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'colors': colors,
        'color': color,
        'material': material,
        'brand': brand,
        'imageUrls': imageUrls,
        'sizeStocks': sizeStocks.map((s) => s.toJson()).toList(),
        'productType': productType,
        'fabricType': fabricType,
        'fabricQuality': fabricQuality,
        'fabricWidthCm': fabricWidthCm,
        'fabricWeightGsm': fabricWeightGsm,
        'fabricPattern': fabricPattern,
        'fabricOrigin': fabricOrigin,
        'fabricCare': fabricCare,
        'isFeatured': isFeatured,
        'discountPercent': discountPercent,
        'discountAmount': discountAmount,
        'discountType': discountType,
        'discountForAllCustomers': discountForAllCustomers,
        'discountCustomerIds': discountCustomerIds,
        'discountSetBy': discountSetBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final colorsJson = json['colors'];
    final List<String> colors;
    if (colorsJson is List) {
      colors = List<String>.from(colorsJson);
    } else if (json['color'] is String && (json['color'] as String).isNotEmpty) {
      colors = [(json['color'] as String)];
    } else {
      colors = const ['ڕەش'];
    }

    return ProductModel(
      id: json['id'] as String,
      shopOwnerId: json['shopOwnerId'] as String,
      shopName: json['shopName'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      colors: colors,
      material: json['material'] as String,
      brand: json['brand'] as String,
      imageUrls: List<String>.from(json['imageUrls'] as List),
      sizeStocks: (json['sizeStocks'] as List? ?? [])
          .map((s) => SizeStock.fromJson(s as Map<String, dynamic>))
          .toList(),
      productType: json['productType'] as String? ?? ProductKind.clothing,
      fabricType: json['fabricType'] as String? ?? '',
      fabricQuality: json['fabricQuality'] as String? ?? '',
      fabricWidthCm: (json['fabricWidthCm'] as num?)?.toDouble() ?? 0,
      fabricWeightGsm: (json['fabricWeightGsm'] as num?)?.toInt() ?? 0,
      fabricPattern: json['fabricPattern'] as String? ?? '',
      fabricOrigin: json['fabricOrigin'] as String? ?? '',
      fabricCare: json['fabricCare'] as String? ?? '',
      isFeatured: json['isFeatured'] as bool? ?? false,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      discountType: json['discountType'] as String? ?? DiscountKind.percent,
      discountForAllCustomers:
          json['discountForAllCustomers'] as bool? ?? true,
      discountCustomerIds: (json['discountCustomerIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      discountSetBy: json['discountSetBy'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
