import '../../models/order_model.dart';
import '../../models/user_model.dart';

class CustomerPurchaseRank {
  final String userId;
  final String name;
  final int orderCount;
  final double totalSpent;
  final int itemCount;

  const CustomerPurchaseRank({
    required this.userId,
    required this.name,
    required this.orderCount,
    required this.totalSpent,
    required this.itemCount,
  });
}

class ShopSalesRank {
  final String key;
  final String shopName;
  final String? ownerId;
  final int orderCount;
  final double totalSales;
  final int itemCount;

  const ShopSalesRank({
    required this.key,
    required this.shopName,
    required this.orderCount,
    required this.totalSales,
    required this.itemCount,
    this.ownerId,
  });
}

/// Rankings for admin ERP reports (excludes cancelled orders).
class AdminSalesRankings {
  AdminSalesRankings._();

  static bool _counts(OrderModel o) =>
      o.status != OrderStatus.cancelled &&
      o.status != OrderStatus.returned &&
      o.status != OrderStatus.pending;

  static List<CustomerPurchaseRank> topCustomers(
    List<OrderModel> orders, {
    List<UserModel> users = const [],
    int limit = 10,
  }) {
    final byUser = <String, _Agg>{};
    final nameById = {
      for (final u in users) u.id: u.name.trim().isEmpty ? 'کڕیار' : u.name,
    };

    for (final order in orders.where(_counts)) {
      final id = order.userId.trim();
      if (id.isEmpty) continue;
      final agg = byUser.putIfAbsent(id, () => _Agg());
      agg.orders += 1;
      agg.amount += order.total;
      agg.items += order.itemCount;
      if (order.customerName.trim().isNotEmpty) {
        agg.fallbackName = order.customerName.trim();
      }
    }

    final ranks = byUser.entries.map((e) {
      return CustomerPurchaseRank(
        userId: e.key,
        name: nameById[e.key] ?? e.value.fallbackName ?? 'کڕیار',
        orderCount: e.value.orders,
        totalSpent: e.value.amount,
        itemCount: e.value.items,
      );
    }).toList()
      ..sort((a, b) {
        final bySpend = b.totalSpent.compareTo(a.totalSpent);
        if (bySpend != 0) return bySpend;
        return b.orderCount.compareTo(a.orderCount);
      });

    if (ranks.length <= limit) return ranks;
    return ranks.sublist(0, limit);
  }

  static List<ShopSalesRank> topShops(
    List<OrderModel> orders, {
    int limit = 10,
  }) {
    final byShop = <String, _ShopAgg>{};

    for (final order in orders.where(_counts)) {
      // Prefer per-item shop attribution when multi-shop orders exist.
      final seenInOrder = <String>{};
      for (final item in order.items) {
        final owner = item.shopOwnerId.trim();
        final name = item.shopName.trim().isEmpty
            ? (order.shopName.trim().isEmpty ? 'دووکان' : order.shopName.trim())
            : item.shopName.trim();
        final key = owner.isNotEmpty ? 'id:$owner' : 'name:$name';
        final agg = byShop.putIfAbsent(
          key,
          () => _ShopAgg(shopName: name, ownerId: owner.isEmpty ? null : owner),
        );
        if (agg.shopName == 'دووکان' && name != 'دووکان') {
          agg.shopName = name;
        }
        agg.amount += item.lineTotal;
        agg.items += item.quantity;
        seenInOrder.add(key);
      }

      if (order.items.isEmpty) {
        final owner = order.shopOwnerId.trim();
        final name =
            order.shopName.trim().isEmpty ? 'دووکان' : order.shopName.trim();
        final key = owner.isNotEmpty ? 'id:$owner' : 'name:$name';
        final agg = byShop.putIfAbsent(
          key,
          () => _ShopAgg(shopName: name, ownerId: owner.isEmpty ? null : owner),
        );
        agg.amount += order.total;
        agg.items += order.itemCount;
        seenInOrder.add(key);
      }

      for (final key in seenInOrder) {
        byShop[key]?.orders += 1;
      }
    }

    final ranks = byShop.entries.map((e) {
      return ShopSalesRank(
        key: e.key,
        shopName: e.value.shopName,
        ownerId: e.value.ownerId,
        orderCount: e.value.orders,
        totalSales: e.value.amount,
        itemCount: e.value.items,
      );
    }).toList()
      ..sort((a, b) {
        final bySales = b.totalSales.compareTo(a.totalSales);
        if (bySales != 0) return bySales;
        return b.orderCount.compareTo(a.orderCount);
      });

    if (ranks.length <= limit) return ranks;
    return ranks.sublist(0, limit);
  }
}

class _Agg {
  int orders = 0;
  double amount = 0;
  int items = 0;
  String? fallbackName;
}

class _ShopAgg {
  String shopName;
  String? ownerId;
  int orders = 0;
  double amount = 0;
  int items = 0;

  _ShopAgg({required this.shopName, this.ownerId});
}
