class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String shopOwnerId;
  final String shopName;
  final String productId;
  final String productName;
  final String category;
  final String? imageUrl;

  /// When set, only this user should see the notification.
  final String? targetUserId;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.shopOwnerId,
    required this.shopName,
    required this.productId,
    required this.productName,
    required this.category,
    this.imageUrl,
    this.targetUserId,
    required this.createdAt,
  });

  static const typeNewProduct = 'new_product';
  static const typeAccountApproved = 'account_approved';
  static const typeAdminAnnouncement = 'admin_announcement';
  static const typeDiscountAssigned = 'discount_assigned';
  static const typeOrderReady = 'order_ready';
  static const typeOrderDelivered = 'order_delivered';

  bool get isAccountApproved => type == typeAccountApproved;
  bool get isAdminAnnouncement => type == typeAdminAnnouncement;
  bool get isDiscountAssigned => type == typeDiscountAssigned;
  bool get isOrderReady => type == typeOrderReady;
  bool get isOrderDelivered => type == typeOrderDelivered;

  Map<String, dynamic> toJson() {
    final target = targetUserId?.trim() ?? '';
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'shopOwnerId': shopOwnerId,
      'shopName': shopName,
      'productId': productId,
      'productName': productName,
      'category': category,
      'imageUrl': imageUrl,
      if (target.isNotEmpty) 'targetUserId': target,
      'audience': target.isEmpty ? 'all' : 'user',
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? typeNewProduct,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      shopOwnerId: json['shopOwnerId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      targetUserId: json['targetUserId'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
