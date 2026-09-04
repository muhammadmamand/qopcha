import 'cart_item.dart';
import 'body_measurements.dart';
import 'delivery_zone.dart';

enum OrderStatus {
  pending,
  confirmed,
  ready,
  shipped,
  completed,
  cancelled,
  returned,
}

/// Preset reasons a customer can pick when returning a delivered order.
class OrderReturnReasons {
  OrderReturnReasons._();

  static const List<String> presets = [
    'قەبارە / سایز گونجاو نییە',
    'کوالیتی خراپە یان زیانی هەیە',
    'کاڵا وەک وەسف نییە',
    'گۆڕینی بڕیار',
    'هەڵەی داواکاری',
    'هۆکاری تر',
  ];
}

class OrderModel {
  final String id;
  final String userId;
  final String customerName;

  /// Snapshot taken when the order is placed, for the shop owner.
  final BodyMeasurements customerMeasurements;
  final String? customerPreferredSize;
  final DateTime createdAt;
  final List<CartItem> items;
  final double total;
  final OrderStatus status;

  /// Owner of the shop that must accept this order.
  final String shopOwnerId;
  final String shopName;
  final DeliveryZone? deliveryZone;
  final double deliveryFee;
  final String? deliveryAddress;
  final String? deliveryAddressLabel;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  /// When the shop/admin last changed [status].
  final DateTime? statusUpdatedAt;

  /// Customer return request (set when status is [OrderStatus.returned]).
  final String? returnReason;
  final String? returnNote;
  final DateTime? returnRequestedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.items,
    required this.total,
    this.customerName = 'کڕیار',
    this.customerMeasurements = BodyMeasurements.empty,
    this.customerPreferredSize,
    this.status = OrderStatus.pending,
    this.shopOwnerId = '',
    this.shopName = '',
    this.deliveryZone,
    this.deliveryFee = 0,
    this.deliveryAddress,
    this.deliveryAddressLabel,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.statusUpdatedAt,
    this.returnReason,
    this.returnNote,
    this.returnRequestedAt,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  double get itemsSubtotal => items.fold(0.0, (sum, i) => sum + i.lineTotal);

  String get deliveryZoneLabel =>
      deliveryZone?.labelKu ?? (deliveryFee > 0 ? 'گەیاندن' : '—');

  String get shortId {
    final raw = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (raw.length >= 6) return raw.substring(0, 6).toUpperCase();
    return id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();
  }

  String get statusLabel => switch (status) {
    OrderStatus.pending => 'چاوەڕوان',
    OrderStatus.confirmed => 'قبوڵکراو',
    OrderStatus.ready => 'ئامادەیە',
    OrderStatus.shipped => 'نێردراو',
    OrderStatus.completed => 'گەیشتوو',
    OrderStatus.cancelled => 'ڕەتکراوە',
    OrderStatus.returned => 'گەڕاوەتەوە',
  };

  String get statusDetail => switch (status) {
    OrderStatus.pending => 'چاوەڕوانی قبوڵکردنی دووکان',
    OrderStatus.confirmed => 'قبوڵکرا — دووکان ئامادەی دەکات',
    OrderStatus.ready => 'دووکان ئامادەی کردووە — چاوەڕوانی گەیاندن',
    OrderStatus.shipped => 'لە ڕێگای گەیاندندایە',
    OrderStatus.completed => 'گەیەندرا بۆ کڕیار',
    OrderStatus.cancelled => 'ڕەتکرایەوە / هەڵوەشاوە',
    OrderStatus.returned => returnReason?.trim().isNotEmpty == true
        ? 'داواکاری گەڕاندنەوە: ${returnReason!.trim()}'
        : 'کڕیار داوای گەڕاندنەوەی کردووە',
  };

  double get grandTotal => total + deliveryFee;

  bool get canRequestReturn => status == OrderStatus.completed;

  List<CartItem> itemsForShop(String name) =>
      items.where((i) => i.shopName == name).toList();

  double totalForShop(String name) =>
      itemsForShop(name).fold(0.0, (sum, i) => sum + i.lineTotal);

  bool belongsToShop(String name) {
    final n = name.trim();
    if (n.isEmpty) return false;
    if (shopName.trim() == n) return true;
    return items.any((i) => i.shopName.trim() == n);
  }

  bool belongsToShopOwner(String ownerId) {
    final id = ownerId.trim();
    if (id.isEmpty) return false;
    if (shopOwnerId.trim() == id) return true;
    return items.any((i) => i.shopOwnerId.trim() == id);
  }

  List<String> get shopNames {
    final names = <String>[];
    if (shopName.trim().isNotEmpty) names.add(shopName.trim());
    for (final item in items) {
      final name = item.shopName.trim();
      if (name.isNotEmpty && !names.contains(name)) names.add(name);
    }
    return names;
  }

  String get shopsLabel => shopNames.isEmpty ? '—' : shopNames.join('، ');

  DateTime get lastStatusAt =>
      returnRequestedAt ?? statusUpdatedAt ?? createdAt;

  bool isUnseenSince(DateTime? seenAt) {
    if (seenAt == null) return true;
    return lastStatusAt.isAfter(seenAt);
  }

  bool isUnseenCompleted(DateTime? seenAt) =>
      status == OrderStatus.completed && isUnseenSince(seenAt);

  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerName,
    BodyMeasurements? customerMeasurements,
    String? customerPreferredSize,
    DateTime? createdAt,
    List<CartItem>? items,
    double? total,
    OrderStatus? status,
    String? shopOwnerId,
    String? shopName,
    DeliveryZone? deliveryZone,
    double? deliveryFee,
    String? deliveryAddress,
    String? deliveryAddressLabel,
    double? deliveryLatitude,
    double? deliveryLongitude,
    DateTime? statusUpdatedAt,
    String? returnReason,
    String? returnNote,
    DateTime? returnRequestedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerMeasurements: customerMeasurements ?? this.customerMeasurements,
      customerPreferredSize:
          customerPreferredSize ?? this.customerPreferredSize,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      shopOwnerId: shopOwnerId ?? this.shopOwnerId,
      shopName: shopName ?? this.shopName,
      deliveryZone: deliveryZone ?? this.deliveryZone,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryAddressLabel: deliveryAddressLabel ?? this.deliveryAddressLabel,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      returnReason: returnReason ?? this.returnReason,
      returnNote: returnNote ?? this.returnNote,
      returnRequestedAt: returnRequestedAt ?? this.returnRequestedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'customerName': customerName,
    'customerMeasurements': customerMeasurements.toJson(),
    if (customerPreferredSize != null)
      'customerPreferredSize': customerPreferredSize,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'total': total,
    'status': status.name,
    'shopOwnerId': shopOwnerId,
    'shopName': shopName,
    if (deliveryZone != null) 'deliveryZone': deliveryZone!.name,
    'deliveryFee': deliveryFee,
    if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
    if (deliveryAddressLabel != null)
      'deliveryAddressLabel': deliveryAddressLabel,
    if (deliveryLatitude != null) 'deliveryLatitude': deliveryLatitude,
    if (deliveryLongitude != null) 'deliveryLongitude': deliveryLongitude,
    if (statusUpdatedAt != null)
      'statusUpdatedAt': statusUpdatedAt!.toIso8601String(),
    if (returnReason != null) 'returnReason': returnReason,
    if (returnNote != null) 'returnNote': returnNote,
    if (returnRequestedAt != null)
      'returnRequestedAt': returnRequestedAt!.toIso8601String(),
  };

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final raw = json['status'] as String? ?? 'pending';
    final normalized = switch (raw) {
      'delivered' => 'completed',
      _ => raw,
    };
    final status = OrderStatus.values.firstWhere(
      (s) => s.name == normalized,
      orElse: () => OrderStatus.pending,
    );

    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();

    var shopOwnerId = json['shopOwnerId'] as String? ?? '';
    var shopName = json['shopName'] as String? ?? '';
    if (shopOwnerId.isEmpty && items.isNotEmpty) {
      shopOwnerId = items.first.shopOwnerId;
    }
    if (shopName.isEmpty && items.isNotEmpty) {
      shopName = items.first.shopName;
    }

    return OrderModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'کڕیار',
      customerMeasurements: json['customerMeasurements'] is Map
          ? BodyMeasurements.fromJson(
              Map<String, dynamic>.from(json['customerMeasurements'] as Map),
            )
          : BodyMeasurements.empty,
      customerPreferredSize: json['customerPreferredSize'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      items: items,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: status,
      shopOwnerId: shopOwnerId,
      shopName: shopName,
      deliveryZone: DeliveryZone.tryParse(json['deliveryZone'] as String?),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      deliveryAddress: json['deliveryAddress'] as String?,
      deliveryAddressLabel: json['deliveryAddressLabel'] as String?,
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
      statusUpdatedAt: DateTime.tryParse(
        json['statusUpdatedAt'] as String? ?? '',
      ),
      returnReason: json['returnReason'] as String?,
      returnNote: json['returnNote'] as String?,
      returnRequestedAt: DateTime.tryParse(
        json['returnRequestedAt'] as String? ?? '',
      ),
    );
  }
}
