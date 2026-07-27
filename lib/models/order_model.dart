import 'cart_item.dart';

enum OrderStatus { pending, completed, cancelled }

class OrderModel {
  final String id;
  final String userId;
  final String customerName;
  final DateTime createdAt;
  final List<CartItem> items;
  final double total;
  final OrderStatus status;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.items,
    required this.total,
    this.customerName = 'کڕیار',
    this.status = OrderStatus.completed,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  String get statusLabel => switch (status) {
        OrderStatus.pending => 'چاوەڕوان',
        OrderStatus.completed => 'تەواو',
        OrderStatus.cancelled => 'هەڵوەشاوە',
      };

  List<CartItem> itemsForShop(String shopName) =>
      items.where((i) => i.shopName == shopName).toList();

  double totalForShop(String shopName) =>
      itemsForShop(shopName).fold(0.0, (sum, i) => sum + i.lineTotal);

  bool belongsToShop(String shopName) =>
      items.any((i) => i.shopName == shopName);

  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerName,
    DateTime? createdAt,
    List<CartItem>? items,
    double? total,
    OrderStatus? status,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'customerName': customerName,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'total': total,
        'status': status.name,
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        customerName: json['customerName'] as String? ?? 'کڕیار',
        createdAt: DateTime.parse(json['createdAt'] as String),
        items: (json['items'] as List<dynamic>)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toDouble(),
        status: OrderStatus.values.byName(
          json['status'] as String? ?? 'completed',
        ),
      );
}
