import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/order_model.dart';
import 'auth_provider.dart';

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  OrdersNotifier(this._ref) : super([]) {
    _ref.listen(currentUserProvider, (previous, next) {
      _load(next?.id);
    });
    _load(_ref.read(currentUserProvider)?.id);
  }

  final Ref _ref;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  Future<void> _load(String? userId) async {
    if (userId == null) {
      state = [];
      return;
    }

    final snap = await _orders.where('userId', isEqualTo: userId).get();

    state = snap.docs.map(_fromDoc).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<OrderModel?> placeOrder(List<CartItem> items) async {
    final user = _ref.read(currentUserProvider);
    if (user == null || items.isEmpty) return null;

    final ref = _orders.doc();
    final order = OrderModel(
      id: ref.id,
      userId: user.id,
      customerName: user.name,
      createdAt: DateTime.now(),
      items: List<CartItem>.from(items),
      total: items.fold(0.0, (t, i) => t + i.lineTotal),
      status: OrderStatus.pending,
    );

    await ref.set(order.toJson());
    state = [order, ...state];
    await _ref.read(shopOrdersNotifierProvider.notifier).load();
    return order;
  }

  OrderModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return OrderModel.fromJson(data);
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<OrderModel>>((ref) {
  return OrdersNotifier(ref);
});

final ordersCountProvider = Provider<int>((ref) {
  return ref.watch(ordersProvider).length;
});

class ShopOrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  ShopOrdersNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final _db = FirebaseFirestore.instance;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      final shopName = user?.shopName?.trim();
      if (user == null || !user.isShopOwner || shopName == null || shopName.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      final snap = await _db.collection('orders').get();

      final orders = snap.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return OrderModel.fromJson(data);
          })
          .where((o) => o.belongsToShop(shopName))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _db.collection('orders').doc(orderId).update({'status': status.name});
    await load();
  }
}

final shopOrdersNotifierProvider =
    StateNotifierProvider<ShopOrdersNotifier, AsyncValue<List<OrderModel>>>(
  (ref) => ShopOrdersNotifier(ref),
);

final shopOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((ref) {
  return ref.watch(shopOrdersNotifierProvider);
});

final shopPendingOrdersCountProvider = Provider<int>((ref) {
  final async = ref.watch(shopOrdersProvider);
  return async.maybeWhen(
    data: (orders) =>
        orders.where((o) => o.status == OrderStatus.pending).length,
    orElse: () => 0,
  );
});
