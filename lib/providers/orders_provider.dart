import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address_model.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  OrdersNotifier(this._ref) : super([]) {
    _ref.listen(currentUserProvider, (previous, next) {
      _bind(next?.id);
    });
    _bind(_ref.read(currentUserProvider)?.id);
  }

  final Ref _ref;
  final _api = ApiClient.instance;
  StreamSubscription<List<OrderModel>>? _sub;

  void _bind(String? userId) {
    _sub?.cancel();
    if (userId == null) {
      state = [];
      return;
    }
    _sub = _api.poll(_fetchMine).listen(
      (list) => state = list,
      onError: (_) {},
    );
  }

  Future<List<OrderModel>> _fetchMine() async {
    final data = await _api.getJson('/api/orders');
    final list = (data['orders'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => OrderModel.fromJson(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<OrderModel>> placeOrder(
    List<CartItem> items, {
    AddressModel? deliveryAddress,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null || items.isEmpty) return const [];
    if (!user.canPlaceOrders) {
      throw Exception(
        user.isPending
            ? 'هەژمارەکەت هێشتا پەسەند نەکراوە — ناتوانیت داواکاری بکەیت'
            : 'ناتوانیت داواکاری بکەیت',
      );
    }

    final addressText = deliveryAddress?.location.trim().isNotEmpty == true
        ? deliveryAddress!.location.trim()
        : (user.location?.trim() ?? '');
    if (addressText.isEmpty) {
      throw Exception('تکایە ناونیشانێک هەڵبژێرە');
    }

    final groups = <String, List<CartItem>>{};
    for (final item in items) {
      final key = item.shopOwnerId.trim().isNotEmpty
          ? 'id:${item.shopOwnerId.trim()}'
          : 'name:${item.shopName.trim()}';
      groups.putIfAbsent(key, () => []).add(item);
    }

    final payloads = <Map<String, dynamic>>[];
    for (final entry in groups.entries) {
      final groupItems = entry.value;
      final ownerId = groupItems.first.shopOwnerId.trim();
      final shop = groupItems.first.shopName.trim().isEmpty
          ? 'دووکان'
          : groupItems.first.shopName.trim();
      final subtotal = groupItems.fold(0.0, (t, i) => t + i.lineTotal);
      final order = OrderModel(
        id: '',
        userId: user.id,
        customerName: user.name,
        customerMeasurements: user.measurements,
        customerPreferredSize:
            user.measurements.suggestedSize ?? user.preferredSize,
        createdAt: DateTime.now(),
        items: List<CartItem>.from(groupItems),
        total: subtotal,
        status: OrderStatus.pending,
        shopOwnerId: ownerId,
        shopName: shop,
        deliveryAddress: addressText,
        deliveryAddressLabel: deliveryAddress?.label,
        deliveryLatitude: deliveryAddress?.latitude ?? user.latitude,
        deliveryLongitude: deliveryAddress?.longitude ?? user.longitude,
      );
      payloads.add(order.toJson());
    }

    final data = await _api.postJson('/api/orders', {'orders': payloads});
    final created = (data['orders'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => OrderModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    await _ref.read(shopOrdersNotifierProvider.notifier).load();
    state = await _fetchMine();
    return created;
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _api.patchJson('/api/orders/$orderId', {'status': status.name});
    await _ref.read(shopOrdersNotifierProvider.notifier).load();
    state = await _fetchMine();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<OrderModel>>((
  ref,
) {
  return OrdersNotifier(ref);
});

final ordersCountProvider = Provider<int>((ref) {
  return ref.watch(ordersProvider).length;
});

final unseenDeliveredOrdersCountProvider = Provider<int>((ref) {
  return ref.watch(unseenOrderTabCountsProvider)['delivered'] ?? 0;
});

const _orderTabStatuses = <String, List<OrderStatus>>{
  'pending': [OrderStatus.pending],
  'confirmed': [OrderStatus.confirmed],
  'ready': [OrderStatus.ready],
  'shipped': [OrderStatus.shipped],
  'delivered': [OrderStatus.completed],
  'returned': [OrderStatus.cancelled],
};

final unseenOrderTabCountsProvider = Provider<Map<String, int>>((ref) {
  final user = ref.watch(currentUserProvider);
  final orders = ref.watch(ordersProvider);
  return {
    for (final entry in _orderTabStatuses.entries)
      entry.key: orders
          .where(
            (o) =>
                entry.value.contains(o.status) &&
                o.isUnseenSince(user?.orderTabSeenAt(entry.key)),
          )
          .length,
  };
});

class ShopOrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  ShopOrdersNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
    _ref.listen(currentUserProvider, (prev, next) {
      load();
    });
  }

  final Ref _ref;
  final _api = ApiClient.instance;
  StreamSubscription<List<OrderModel>>? _sub;

  Future<void> load() async {
    _sub?.cancel();
    final user = _ref.read(currentUserProvider);
    if (user == null || !user.isShopOwner) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      _sub = _api.poll(() async {
        final data = await _api.getJson('/api/orders');
        final shopName = user.shopName?.trim() ?? '';
        final orders = (data['orders'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => OrderModel.fromJson(Map<String, dynamic>.from(m)))
            .where(
              (o) =>
                  o.belongsToShopOwner(user.id) ||
                  (shopName.isNotEmpty && o.belongsToShop(shopName)),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      }).listen(
        (orders) => state = AsyncValue.data(orders),
        onError: (e, st) => state = AsyncValue.error(e, st),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _api.patchJson('/api/orders/$orderId', {
      'status': status.name,
      'statusUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markReady(OrderModel order) async {
    final shop = _ref.read(currentUserProvider);
    if (shop == null || !shop.isShopOwner) return;
    if (order.status != OrderStatus.confirmed) return;
    if (!order.belongsToShopOwner(shop.id)) {
      final name = shop.shopName?.trim() ?? '';
      if (name.isEmpty || !order.belongsToShop(name)) return;
    }

    await _api.patchJson('/api/orders/${order.id}', {
      'status': OrderStatus.ready.name,
      'statusUpdatedAt': DateTime.now().toIso8601String(),
      'readyAt': DateTime.now().toIso8601String(),
    });

    try {
      await NotificationService().announceOrderReady(
        userId: order.userId,
        orderId: order.id,
        shopOwnerId: shop.id,
        shopName: shop.shopName ?? order.shopName,
        imageUrl: order.items.isEmpty ? null : order.items.first.imageUrl,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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
  return ref.watch(shopOrdersProvider).maybeWhen(
        data: (orders) =>
            orders.where((o) => o.status == OrderStatus.pending).length,
        orElse: () => 0,
      );
});
