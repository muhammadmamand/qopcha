import '../../models/product_model.dart';

/// Local English clothing demos for App Store / Play review when the
/// live catalog is sparse or images are missing.
class ReviewDemoCatalog {
  ReviewDemoCatalog._();

  static const shopOwnerId = 'review-demo-shop';
  static const shopName = 'Qopcha Demo Shop';

  static List<ProductModel> get products {
    final now = DateTime.now();
    return [
      _item(
        id: 'demo_white_shirt',
        name: 'Classic White Shirt',
        description: 'Soft cotton shirt for everyday wear.',
        category: 'کراس',
        price: 35000,
        colors: const ['White', 'Black'],
        material: 'Cotton',
        image:
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800',
        sizes: const [
          SizeStock(size: 'M', quantity: 8),
          SizeStock(size: 'L', quantity: 10),
        ],
        featured: true,
        now: now,
      ),
      _item(
        id: 'demo_summer_dress',
        name: 'Summer Floral Dress',
        description: 'Light modern dress for summer days.',
        category: 'پۆشاک',
        price: 55000,
        colors: const ['Pink', 'White'],
        material: 'Linen',
        image:
            'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=800',
        sizes: const [
          SizeStock(size: 'S', quantity: 5),
          SizeStock(size: 'M', quantity: 7),
        ],
        featured: true,
        discountPercent: 15,
        now: now,
      ),
      _item(
        id: 'demo_blue_jeans',
        name: 'Slim Blue Jeans',
        description: 'Comfortable denim jeans for daily use.',
        category: 'پانتۆڵ',
        price: 48000,
        colors: const ['Blue'],
        material: 'Denim',
        image:
            'https://images.unsplash.com/photo-1542272604-787c3835535d?w=800',
        sizes: const [
          SizeStock(size: '32', quantity: 6),
          SizeStock(size: '34', quantity: 5),
        ],
        featured: true,
        now: now,
      ),
      _item(
        id: 'demo_winter_coat',
        name: 'Warm Winter Coat',
        description: 'Modern warm coat for cold weather.',
        category: 'کۆت',
        price: 89000,
        colors: const ['Black', 'Brown'],
        material: 'Wool',
        image:
            'https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=800',
        sizes: const [
          SizeStock(size: 'L', quantity: 4),
          SizeStock(size: 'XL', quantity: 3),
        ],
        featured: true,
        now: now,
      ),
      _item(
        id: 'demo_sneakers',
        name: 'Urban White Sneakers',
        description: 'Clean white sneakers for casual outfits.',
        category: 'پێڵاو',
        price: 62000,
        colors: const ['White'],
        material: 'Canvas',
        image:
            'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800',
        sizes: const [
          SizeStock(size: '40', quantity: 5),
          SizeStock(size: '41', quantity: 5),
          SizeStock(size: '42', quantity: 5),
        ],
        featured: true,
        now: now,
      ),
      _item(
        id: 'demo_hoodie',
        name: 'Soft Black Hoodie',
        description: 'Cozy hoodie for cool evenings.',
        category: 'پۆشاک',
        price: 42000,
        colors: const ['Black', 'Grey'],
        material: 'Cotton blend',
        image:
            'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800',
        sizes: const [
          SizeStock(size: 'M', quantity: 9),
          SizeStock(size: 'L', quantity: 9),
        ],
        featured: true,
        now: now,
      ),
      _item(
        id: 'demo_leather_bag',
        name: 'Brown Leather Bag',
        description: 'Everyday leather-style bag.',
        category: 'جانتە',
        price: 75000,
        colors: const ['Brown'],
        material: 'Leather',
        image:
            'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800',
        sizes: const [SizeStock(size: 'One Size', quantity: 12)],
        featured: false,
        now: now,
      ),
      _item(
        id: 'demo_cap',
        name: 'Navy Baseball Cap',
        description: 'Simple navy cap for sunny days.',
        category: 'کڵاو',
        price: 18000,
        colors: const ['Navy'],
        material: 'Cotton',
        image:
            'https://images.unsplash.com/photo-1588850561407-ed78c63e2248?w=800',
        sizes: const [SizeStock(size: 'One Size', quantity: 20)],
        featured: false,
        now: now,
      ),
    ];
  }

  static ProductModel? byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Merge live products with demos so App Review always sees clothing.
  static List<ProductModel> mergeWith(List<ProductModel> live) {
    final ids = live.map((p) => p.id).toSet();
    final names = live.map((p) => p.name.trim().toLowerCase()).toSet();
    final extras = products.where((p) {
      return !ids.contains(p.id) && !names.contains(p.name.toLowerCase());
    });
    return [...live, ...extras]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static ProductModel _item({
    required String id,
    required String name,
    required String description,
    required String category,
    required double price,
    required List<String> colors,
    required String material,
    required String image,
    required List<SizeStock> sizes,
    required bool featured,
    required DateTime now,
    double discountPercent = 0,
  }) {
    return ProductModel(
      id: id,
      shopOwnerId: shopOwnerId,
      shopName: shopName,
      name: name,
      description: description,
      category: category,
      price: price,
      colors: colors,
      material: material,
      brand: 'Qopcha',
      imageUrls: [image],
      colorImages: const {},
      sizeStocks: sizes,
      productType: ProductKind.clothing,
      fabricType: '',
      fabricQuality: '',
      fabricWidthCm: 0,
      fabricWeightGsm: 0,
      fabricPattern: '',
      fabricOrigin: '',
      fabricCare: '',
      isFeatured: featured,
      discountPercent: discountPercent,
      discountAmount: 0,
      discountType: DiscountKind.percent,
      discountForAllCustomers: true,
      discountCustomerIds: const [],
      discountSetBy: discountPercent > 0 ? 'shop' : '',
      createdAt: now,
      updatedAt: now,
    );
  }
}
