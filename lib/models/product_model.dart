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
  final bool isFeatured;
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
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display string for UI (joined colors).
  String get color => colors.isEmpty ? '' : colors.join('، ');

  int get totalStock => sizeStocks.fold(0, (sum, s) => sum + s.quantity);

  bool get inStock => totalStock > 0;

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
    bool? isFeatured,
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
      isFeatured: isFeatured ?? this.isFeatured,
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
        'isFeatured': isFeatured,
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
      sizeStocks: (json['sizeStocks'] as List)
          .map((s) => SizeStock.fromJson(s as Map<String, dynamic>))
          .toList(),
      isFeatured: json['isFeatured'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
