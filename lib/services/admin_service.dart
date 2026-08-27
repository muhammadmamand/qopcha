import '../models/app_content_model.dart';
import '../models/banner_model.dart';
import '../models/delivery_zone.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'notification_service.dart';

class AdminService {
  final _api = ApiClient.instance;

  Stream<List<UserModel>> watchUsers({ApprovalStatus? status}) {
    return _api.poll(() async {
      final data = await _api.getJson('/api/users');
      var list = (data['users'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => UserModel.fromJson(Map<String, dynamic>.from(m)))
          .where((u) => !u.isAdmin)
          .toList();
      if (status != null) {
        list = list.where((u) => u.approvalStatus == status).toList();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> setApproval(
    String userId,
    ApprovalStatus status, {
    String? rejectionReason,
  }) async {
    final data = <String, dynamic>{
      'approvalStatus': status.name,
    };
    if (status == ApprovalStatus.rejected) {
      final reason = (rejectionReason ?? '').trim();
      data['rejectionReason'] = reason.isEmpty
          ? 'هەژمارەکەت لەلایەن ئەدمینەوە ڕەتکرایەوە'
          : reason;
    } else {
      data['rejectionReason'] = null;
    }
    if (status == ApprovalStatus.approved) {
      data['approvalNoticeSeen'] = false;
    }
    final res = await _api.patchJson('/api/users/$userId', data);
    if (status == ApprovalStatus.approved) {
      try {
        final raw = res['user'];
        if (raw is Map) {
          final user = UserModel.fromJson(Map<String, dynamic>.from(raw));
          await NotificationService().announceAccountApproved(
            userId: userId,
            name: user.name,
            isShopOwner: user.isShopOwner,
            shopName: user.shopName,
          );
        }
      } catch (_) {}
    }
  }

  Future<void> setCustomerSpecialDiscount({
    required String userId,
    required double productDiscountPercent,
    required double deliveryDiscountPercent,
  }) async {
    final product = productDiscountPercent.clamp(0, 100).toDouble();
    final delivery = deliveryDiscountPercent.clamp(0, 100).toDouble();
    await _api.patchJson('/api/users/$userId', {
      'productDiscountPercent': product,
      'deliveryDiscountPercent': delivery,
    });
    if (product > 0 || delivery > 0) {
      try {
        await NotificationService().announcePersonalDiscount(
          userId: userId,
          productPercent: product,
          deliveryPercent: delivery,
        );
      } catch (_) {}
    }
  }

  Stream<List<BannerModel>> watchBanners({bool activeOnly = false}) {
    return _api.poll(() async {
      final data = await _api.getJson(
        '/api/banners',
        query: activeOnly ? {'active': '1'} : null,
      );
      var list = (data['banners'] as List? ?? const [])
          .whereType<Map>()
          .map((m) {
            final map = Map<String, dynamic>.from(m);
            return BannerModel.fromJson(map['id'] as String? ?? '', map);
          })
          .toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Future<void> saveBanner(BannerModel banner) async {
    await _api.postJson('/api/banners', {
      ...banner.toJson(),
      if (banner.id.isNotEmpty) 'id': banner.id,
    });
  }

  Future<void> deleteBanner(String id) async {
    await _api.delete('/api/banners/$id');
  }

  Future<void> setBannerActive(String id, bool active) async {
    await _api.postJson('/api/banners', {'id': id, 'active': active});
  }

  Stream<AppContentModel> watchAppContent() {
    return _api.poll(() async {
      final data = await _api.getJson('/api/content');
      final raw = data['content'];
      if (raw is! Map || raw.isEmpty) return AppContentModel.defaults();
      return AppContentModel.fromJson(Map<String, dynamic>.from(raw));
    });
  }

  Future<void> saveAppContent(AppContentModel content) async {
    await _api.putJson(
      '/api/content',
      content.copyWith(updatedAt: DateTime.now()).toJson(),
    );
  }

  Stream<List<ProductModel>> watchProducts() {
    return _api.poll(() async {
      final data = await _api.getJson('/api/products');
      final list = (data['products'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => ProductModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Future<void> setProductDiscount(
    String productId,
    double percent, {
    bool forAllCustomers = true,
    List<String> customerIds = const [],
  }) async {
    final clamped = percent.clamp(0, 100);
    final ids = forAllCustomers
        ? <String>[]
        : customerIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    await _api.patchJson('/api/products/$productId', {
      'discountPercent': clamped,
      'discountAmount': 0,
      'discountType': 'percent',
      'discountForAllCustomers': forAllCustomers || clamped <= 0,
      'discountCustomerIds': clamped <= 0 ? <String>[] : ids,
      'discountSetBy': clamped > 0 ? 'admin' : '',
    });
    if (clamped > 0) {
      try {
        final data = await _api.getJson('/api/products/$productId');
        final raw = data['product'];
        if (raw is Map) {
          await NotificationService().announceProductDiscount(
            product: ProductModel.fromJson(Map<String, dynamic>.from(raw)),
            percent: clamped.toDouble(),
            forAllCustomers: forAllCustomers,
            customerIds: ids,
          );
        }
      } catch (_) {}
    }
  }

  Future<void> clearProductDiscount(String productId) async {
    await setProductDiscount(productId, 0);
  }

  Future<void> setProductFeatured(String productId, bool featured) async {
    await _api.patchJson('/api/products/$productId', {'isFeatured': featured});
  }

  Future<void> deleteProduct(String productId) async {
    await _api.delete('/api/products/$productId');
  }

  Future<void> setShopTier(String userId, ShopTier tier) async {
    await _api.patchJson('/api/users/$userId', {'shopTier': tier.name});
  }

  Stream<List<OrderModel>> watchOrders() {
    return _api.poll(() async {
      final data = await _api.getJson('/api/orders');
      final list = (data['orders'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => OrderModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    Map<String, dynamic>? data;
    if (status == OrderStatus.completed) {
      final snap = await _api.getJson('/api/orders');
      final list = snap['orders'] as List? ?? const [];
      for (final item in list) {
        if (item is Map && item['id'] == orderId) {
          data = Map<String, dynamic>.from(item);
          break;
        }
      }
    }
    await _api.patchJson('/api/orders/$orderId', {'status': status.name});
    if (status != OrderStatus.completed || data == null) return;
    try {
      await NotificationService().announceOrderDelivered(
        OrderModel.fromJson(data),
      );
    } catch (_) {}
  }

  Future<void> setOrderDelivery({
    required String orderId,
    required DeliveryZone zone,
    String? driverNote,
    double deliveryDiscountPercent = 0,
  }) async {
    final fee = zone.fee * (1 - deliveryDiscountPercent.clamp(0, 100) / 100);
    await _api.patchJson('/api/orders/$orderId', {
      'deliveryZone': zone.name,
      'deliveryFee': fee,
      if (driverNote != null) 'driverNote': driverNote.trim(),
      'deliveryUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setOrderDeliveryFee({
    required String orderId,
    required double fee,
    DeliveryZone? zone,
  }) async {
    await _api.patchJson('/api/orders/$orderId', {
      'deliveryFee': fee,
      if (zone != null) 'deliveryZone': zone.name,
      'deliveryUpdatedAt': DateTime.now().toIso8601String(),
    });
  }
}
