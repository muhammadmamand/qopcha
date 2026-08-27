import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _load();
  }

  static const _key = 'shopping_cart';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    state = raw
        .map((j) => CartItem.fromJson(jsonDecode(j) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      state.map((i) => jsonEncode(i.toJson())).toList(),
    );
  }

  int get itemCount => state.fold(0, (sum, i) => sum + i.quantity);

  double get total => state.fold(0.0, (sum, i) => sum + i.lineTotal);

  Future<void> addFromProduct(
    ProductModel product,
    String size, {
    String? customerId,
    double personalDiscountPercent = 0,
  }) async {
    final index = state.indexWhere((i) => i.key == '${product.id}-$size');
    if (index >= 0) {
      final updated = List<CartItem>.from(state);
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + 1,
      );
      state = updated;
    } else {
      state = [
        ...state,
        CartItem(
          productId: product.id,
          name: product.name,
          imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
          shopName: product.shopName,
          shopOwnerId: product.shopOwnerId,
          price: product.salePriceFor(
            customerId,
            personalDiscountPercent: personalDiscountPercent,
          ),
          size: size,
        ),
      ];
    }
    await _save();
  }

  Future<void> addCartItem(CartItem item) async {
    final index = state.indexWhere((i) => i.key == item.key);
    if (index >= 0) {
      final updated = List<CartItem>.from(state);
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + item.quantity,
      );
      state = updated;
    } else {
      state = [...state, item];
    }
    await _save();
  }

  Future<void> updateQuantity(String key, int quantity) async {
    if (quantity < 1) {
      await removeItem(key);
      return;
    }
    state = state
        .map((i) => i.key == key ? i.copyWith(quantity: quantity) : i)
        .toList();
    await _save();
  }

  Future<void> removeItem(String key) async {
    state = state.where((i) => i.key != key).toList();
    await _save();
  }

  Future<void> clear() async {
    state = [];
    await _save();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, i) => sum + i.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0.0, (sum, i) => sum + i.lineTotal);
});
