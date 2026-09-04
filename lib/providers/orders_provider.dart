import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address_model.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

bool _sameOrderList(List<OrderModel> a, List<OrderModel> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x.id != y.id ||
        x.status != y.status ||
        x.total != y.total ||
        x.statusUpdatedAt != y.statusUpdatedAt) {
      return false;
    }
  }
  return true;
}

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  OrdersNotifier(this._ref) : super([]) {
    _ref.listen(currentUserProvider, (previous, next) {
      // Auth polls every few seconds with a new UserModel instance —
      // only rebind when the signed-in user actually changes.
      if (previous?.id == next?.id) return;
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
      (list) {
        if (_sameOrderList(state, list)) return;
        state = list;
      },
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

  Future<OrderModel?> requestReturn(
    String orderId, {
    required String reason,
    String note = '',
  }) async {
    final data = await _api.postJson('/api/orders/$orderId/return', {
      'reason': reason.trim(),
      'note': note.trim(),
    });
    final raw = data['order'];
    state = await _fetchMine();
    if (raw is Map) {
      return OrderModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
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
  'returned': [OrderStatus.returned],
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
      if (prev?.id == next?.id &&
          prev?.isShopOwner == next?.isShopOwner &&
          (prev?.shopName?.trim() ?? '') == (next?.shopName?.trim() ?? '')) {
        return;
      }
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

    // Keep showing existing orders while reconnecting — avoid full-page
    // loading flicker every time auth/poll restarts.
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
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
        (orders) {
          final current = state.valueOrNull;
          if (current != null && _sameOrderList(current, orders)) return;
          state = AsyncValue.data(orders);
        },
        onError: (e, st) {
          if (state.hasValue) return;
          state = AsyncValue.error(e, st);
        },
      );
    } catch (e, st) {
      if (state.hasValue) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _api.patchJson('/api/orders/$orderId', {
      'status': status.name,
      'statusUpdatedAt': DateTime.now().toIso8601String(),
    });
    await _applyLocalStatus(orderId, status);
  }

  Future<void> markReady(OrderModel order) async {
    final shop = _ref.read(currentUserProvider);
    if (shop == null || !shop.isShopOwner) return;
    if (order.status != OrderStatus.confirmed) return;
    if (!order.belongsToShopOwner(shop.id)) {
      final name = shop.shopName?.trim() ?? '';
      if (name.isEmpty || !order.belongsToShop(name)) return;
    }

    final readyAt = DateTime.now();
    await _api.patchJson('/api/orders/${order.id}', {
      'status': OrderStatus.ready.name,
      'statusUpdatedAt': readyAt.toIso8601String(),
      'readyAt': readyAt.toIso8601String(),
    });
    await _applyLocalStatus(order.id, OrderStatus.ready);

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

  Future<void> _applyLocalStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final current = state.valueOrNull;
    if (current == null) {
      await load();
      return;
    }
    final now = DateTime.now();
    state = AsyncValue.data([
      for (final o in current)
        if (o.id == orderId)
          o.copyWith(status: status, statusUpdatedAt: now)
        else
          o,
    ]);
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
