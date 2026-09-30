import '../core/constants/review_demo_catalog.dart';
import '../models/product_model.dart';
import 'api_client.dart';
import 'notification_service.dart';

class ProductService {
  final _api = ApiClient.instance;

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final data = await _api.getJson('/api/products');
      return ReviewDemoCatalog.mergeWith(_list(data));
    } catch (_) {
      return ReviewDemoCatalog.products;
    }
  }

  Future<List<ProductModel>> getProductsByShop(String shopOwnerId) async {
    final data = await _api.getJson('/api/products', query: {
      'shopOwnerId': shopOwnerId,
    });
    final live = _list(data)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (shopOwnerId == ReviewDemoCatalog.shopOwnerId) {
      return ReviewDemoCatalog.mergeWith(live);
    }
    return live;
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final data = await _api.getJson('/api/products', query: {'featured': '1'});
      final merged = ReviewDemoCatalog.mergeWith(_list(data));
      return merged.where((p) => p.isFeatured).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return ReviewDemoCatalog.products.where((p) => p.isFeatured).toList();
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final products = await getAllProducts();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return products;
    return products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.shopName.toLowerCase().contains(q);
    }).toList();
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    if (category == 'هەموو' || category.toLowerCase() == 'all') {
      return getAllProducts();
    }
    try {
      final data = await _api.getJson('/api/products', query: {
        'category': category,
      });
      final live = _list(data);
      final demos = ReviewDemoCatalog.products
          .where((p) => p.category.toLowerCase() == category.toLowerCase());
      return ReviewDemoCatalog.mergeWith([...live, ...demos]);
    } catch (_) {
      return ReviewDemoCatalog.products
          .where((p) => p.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
  }

  Future<ProductModel?> getProductById(String id) async {
    final demo = ReviewDemoCatalog.byId(id);
    if (demo != null) return demo;
    try {
      final data = await _api.getJson('/api/products/$id');
      return _one(data['product']);
    } catch (_) {
      return null;
    }
  }

  Future<ProductModel> addProduct(
    ProductModel product, {
    bool announce = true,
  }) async {
    final payload = product.toJson();
    payload.remove('id');
    final data = await _api.postJson('/api/products', payload);
    final newProduct = _one(data['product'])!;
    if (announce) {
      try {
        await NotificationService().announceNewProduct(newProduct);
      } catch (e, st) {
        assert(() {
          // ignore: avoid_print
          print('announceNewProduct failed: $e\n$st');
          return true;
        }());
      }
      await _announceShopDiscount(newProduct);
    }
    return newProduct;
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    ProductModel? previous;
    try {
      previous = await getProductById(product.id);
    } catch (_) {
      previous = null;
    }
    final updated = product.copyWith(updatedAt: DateTime.now());
    final data = await _api.patchJson('/api/products/${product.id}', updated.toJson());
    final saved = _one(data['product']) ?? updated;
    if (_discountBecameActiveOrChanged(previous, saved)) {
      await _announceShopDiscount(saved);
    }
    return saved;
  }

  Future<void> setProductDiscount({
    required ProductModel product,
    required String shopOwnerId,
    String type = DiscountKind.percent,
    double percent = 0,
    double amount = 0,
  }) async {
    if (product.shopOwnerId != shopOwnerId) {
      throw Exception('ناتوانیت داشکاندن بۆ بەرهەمی دووکانێکی تر دابنێیت');
    }
    final isAmount = type == DiscountKind.amount;
    final clampedPercent = percent.clamp(0, 70).toDouble();
    final maxAmount = product.price > 1 ? product.price - 1 : product.price;
    var clampedAmount = amount < 0 ? 0.0 : amount;
    if (clampedAmount > maxAmount) clampedAmount = maxAmount;
    final active = isAmount ? clampedAmount > 0 : clampedPercent > 0;
    await _api.patchJson('/api/products/${product.id}', {
      'discountType': isAmount ? DiscountKind.amount : DiscountKind.percent,
      'discountPercent': isAmount ? 0 : clampedPercent,
      'discountAmount': isAmount ? clampedAmount : 0,
      'discountForAllCustomers': true,
      'discountCustomerIds': <String>[],
      'discountSetBy': active ? 'shop' : '',
    });
    if (active) {
      final updated = product.copyWith(
        discountType: isAmount ? DiscountKind.amount : DiscountKind.percent,
        discountPercent: isAmount ? 0 : clampedPercent,
        discountAmount: isAmount ? clampedAmount : 0,
        discountForAllCustomers: true,
        discountCustomerIds: const [],
      );
      if (_discountBecameActiveOrChanged(product, updated)) {
        await _announceShopDiscount(updated);
      }
    }
  }

  bool _discountBecameActiveOrChanged(
    ProductModel? before,
    ProductModel after,
  ) {
    if (!after.hasDiscount) return false;
    if (before == null || !before.hasDiscount) return true;
    return before.discountType != after.discountType ||
        before.discountPercent != after.discountPercent ||
        before.discountAmount != after.discountAmount;
  }

  Future<void> _announceShopDiscount(ProductModel product) async {
    if (!product.hasDiscount) return;
    try {
      await NotificationService().announceProductDiscount(
        product: product,
        percent: product.equivalentDiscountPercent,
        forAllCustomers: true,
      );
    } catch (e, st) {
      assert(() {
        // ignore: avoid_print
        print('announceProductDiscount failed: $e\n$st');
        return true;
      }());
    }
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete('/api/products/$id');
  }

  List<ProductModel> _list(Map<String, dynamic> data) {
    final raw = data['products'];
    if (raw is! List) return const [];
    return raw.map(_one).whereType<ProductModel>().toList();
  }

  ProductModel? _one(Object? raw) {
    if (raw is! Map) return null;
    return ProductModel.fromJson(Map<String, dynamic>.from(raw));
  }
}
