import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

final productServiceProvider = Provider<ProductService>((ref) => ProductService());

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(productServiceProvider).getAllProducts();
});

final featuredProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(productServiceProvider).getFeaturedProducts();
});

final shopProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, shopOwnerId) async {
  return ref.watch(productServiceProvider).getProductsByShop(shopOwnerId);
});

final productDetailProvider =
    FutureProvider.family<ProductModel?, String>((ref, productId) async {
  return ref.watch(productServiceProvider).getProductById(productId);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final selectedCategoryProvider = StateProvider<String>((ref) => 'هەموو');

final filteredProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final service = ref.watch(productServiceProvider);
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);

  try {
    List<ProductModel> products;
    if (query.isNotEmpty) {
      products = await service.searchProducts(query);
    } else if (category != 'هەموو') {
      products = await service.getProductsByCategory(category);
    } else {
      products = await service.getAllProducts();
    }
    return products;
  } catch (_) {
    // Show empty search UI instead of a blank/error-only page.
    return <ProductModel>[];
  }
});

class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductService _service;
  final Ref _ref;

  ProductNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<bool> addProduct(ProductModel product) async {
    state = const AsyncValue.loading();
    try {
      await _service.addProduct(product);
      _ref.invalidate(productsProvider);
      _ref.invalidate(featuredProductsProvider);
      _ref.invalidate(filteredProductsProvider);
      _ref.invalidate(shopProductsProvider(product.shopOwnerId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateProduct(product);
      _ref.invalidate(productsProvider);
      _ref.invalidate(featuredProductsProvider);
      _ref.invalidate(filteredProductsProvider);
      _ref.invalidate(shopProductsProvider(product.shopOwnerId));
      _ref.invalidate(productDetailProvider(product.id));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteProduct(String id, String shopOwnerId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteProduct(id);
      _ref.invalidate(productsProvider);
      _ref.invalidate(featuredProductsProvider);
      _ref.invalidate(filteredProductsProvider);
      _ref.invalidate(shopProductsProvider(shopOwnerId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<void>>((ref) {
  return ProductNotifier(ref.watch(productServiceProvider), ref);
});
