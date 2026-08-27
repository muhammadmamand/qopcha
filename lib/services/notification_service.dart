import '../core/utils/formatters.dart';
import '../models/app_notification.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class NotificationService {
  final _api = ApiClient.instance;

  Future<void> _save(AppNotification notification) async {
    await _api.postJson('/api/notifications', notification.toJson());
  }

  Future<void> announceNewProduct(ProductModel product) async {
    final shop = product.shopName.trim().isEmpty
        ? 'دووکان'
        : product.shopName.trim();
    final category = product.category.trim().isEmpty
        ? 'بەرهەم'
        : product.category.trim();
    final name = product.name.trim().isEmpty ? category : product.name.trim();
    await _save(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AppNotification.typeNewProduct,
        title: 'بەرهەمی نوێ',
        body: 'دووکانی $shop $categoryـێکی نوێ زیاد کرد: $name',
        shopOwnerId: product.shopOwnerId,
        shopName: shop,
        productId: product.id,
        productName: name,
        category: category,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> announceAdminBroadcast({
    required String title,
    required String body,
    String category = 'system',
  }) async {
    final t = title.trim();
    final b = body.trim();
    if (t.isEmpty || b.isEmpty) {
      throw ArgumentError('title and body are required');
    }
    await _save(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AppNotification.typeAdminAnnouncement,
        title: t,
        body: b,
        shopOwnerId: '',
        shopName: 'قۆپچە',
        productId: '',
        productName: '',
        category: category.trim().isEmpty ? 'system' : category.trim().toLowerCase(),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> announceAccountApproved({
    required String userId,
    required String name,
    required bool isShopOwner,
    String? shopName,
  }) async {
    final display = name.trim().isEmpty ? 'میوان' : name.trim();
    final shop = (shopName ?? '').trim();
    await _save(
      AppNotification(
        id: 'approved_$userId',
        type: AppNotification.typeAccountApproved,
        title: isShopOwner ? 'دووکانەکەت پەسەند کرا' : 'هەژمارەکەت پەسەند کرا',
        body: isShopOwner
            ? (shop.isEmpty
                ? '$display، هەژماری دووکانەکەت قبوڵ کرا. ئێستا دەتوانیت بەرهەم زیاد بکەیت و فرۆش بکەیت.'
                : '$display، دووکانی «$shop» قبوڵ کرا. ئێستا دەتوانیت بەرهەم زیاد بکەیت و فرۆش بکەیت.')
            : '$display، هەژمارەکەت قبوڵ کرا. ئێستا دەتوانیت داواکاری بکەیت.',
        shopOwnerId: isShopOwner ? userId : '',
        shopName: shop,
        productId: '',
        productName: '',
        category: 'account',
        targetUserId: userId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> announceProductDiscount({
    required ProductModel product,
    required double percent,
    required bool forAllCustomers,
    List<String> customerIds = const [],
  }) async {
    if (!product.hasDiscount) return;
    final value = percent.clamp(0, 100).toDouble();
    if (value <= 0) return;
    final name = product.name.trim().isEmpty ? 'بەرهەم' : product.name.trim();
    final shop = product.shopName.trim().isEmpty
        ? 'دووکان'
        : product.shopName.trim();
    final isAmount = product.isAmountDiscount;
    final title =
        isAmount ? 'داشکاندنی نوێ' : '${value.round()}٪ داشکاندنی نوێ';
    final body = isAmount
        ? 'دووکانی $shop بڕی ${Formatters.grouped(product.discountAmount.round())} دینار لە نرخی «$name» دەکاتەوە.'
        : 'دووکانی $shop داشکاندنی ${value.round()}٪ بۆ «$name» دانا.';
    final targets = forAllCustomers
        ? <String?>[null]
        : customerIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet()
            .map<String?>((id) => id)
            .toList();
    if (targets.isEmpty) return;
    final createdAt = DateTime.now();
    for (final target in targets) {
      await _save(
        AppNotification(
          id: '${product.id}_${target ?? 'all'}_$createdAt',
          type: AppNotification.typeDiscountAssigned,
          title: title,
          body: body,
          shopOwnerId: product.shopOwnerId,
          shopName: shop,
          productId: product.id,
          productName: name,
          category: 'discount',
          imageUrl:
              product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
          targetUserId: target,
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> announcePersonalDiscount({
    required String userId,
    required double productPercent,
    required double deliveryPercent,
  }) async {
    final product = productPercent.clamp(0, 100).toDouble();
    final delivery = deliveryPercent.clamp(0, 100).toDouble();
    if (product <= 0 && delivery <= 0) return;
    final parts = <String>[
      if (product > 0) '${product.round()}٪ لەسەر بەرهەمەکان',
      if (delivery > 0) '${delivery.round()}٪ لەسەر گەیاندن',
    ];
    await _save(
      AppNotification(
        id: 'personal_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        type: AppNotification.typeDiscountAssigned,
        title: 'داشکاندنی تایبەتت بۆ هات',
        body: '${parts.join(' و ')} بۆ هەژمارەکەت زیاد کرا.',
        shopOwnerId: '',
        shopName: 'قۆپچە',
        productId: '',
        productName: '',
        category: 'discount',
        targetUserId: userId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> announceOrderReady({
    required String userId,
    required String orderId,
    required String shopOwnerId,
    required String shopName,
    String? imageUrl,
  }) async {
    final target = userId.trim();
    if (target.isEmpty) return;
    final shop = shopName.trim().isEmpty ? 'دووکان' : shopName.trim();
    final shortId = orderId
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .padRight(6)
        .substring(0, 6)
        .toUpperCase()
        .trim();
    await _save(
      AppNotification(
        id: 'order_ready_$orderId',
        type: AppNotification.typeOrderReady,
        title: 'داواکارییەکەت ئامادەیە',
        body:
            'دووکانی $shop داواکاری #$shortIdـی ئامادە کردووە. بەمزووانە دەگاتە دەستت.',
        shopOwnerId: shopOwnerId,
        shopName: shop,
        productId: orderId,
        productName: '',
        category: 'order',
        imageUrl: imageUrl,
        targetUserId: target,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> announceOrderDelivered(OrderModel order) async {
    final target = order.userId.trim();
    if (target.isEmpty) return;
    final name = order.customerName.trim().isEmpty
        ? 'کڕیار'
        : order.customerName.trim();
    final shops = order.shopNames.isEmpty
        ? 'دووکان'
        : order.shopNames.join('، ');
    final itemNames = order.items
        .map((i) => i.name.trim())
        .where((n) => n.isNotEmpty)
        .take(3)
        .join('، ');
    final extraItems = order.items.length > 3
        ? ' و ${order.items.length - 3}ی تر'
        : '';
    final address = (order.deliveryAddressLabel ?? '').trim().isNotEmpty
        ? order.deliveryAddressLabel!.trim()
        : (order.deliveryAddress ?? '').trim();
    final body = StringBuffer()
      ..writeln(
        'بەڕێز $name، کاڵاکە گەیشت. دەتوانن لە شۆفێری گەیاندنەکە وەری بگرن.',
      )
      ..writeln()
      ..writeln('داواکاری #${order.shortId}')
      ..writeln('دووکان: $shops')
      ..writeln(
        itemNames.isEmpty
            ? 'بەرهەم: ${order.itemCount} دانە'
            : 'بەرهەم: ${order.itemCount} دانە — $itemNames$extraItems',
      );
    if (address.isNotEmpty) body.writeln('ناونیشان: $address');
    body.writeln('کۆی گشتی: ${Formatters.price(order.grandTotal)}');

    await _save(
      AppNotification(
        id: 'order_delivered_${order.id}',
        type: AppNotification.typeOrderDelivered,
        title: 'کاڵاکە گەیشت',
        body: body.toString().trim(),
        shopOwnerId: order.shopOwnerId,
        shopName: shops,
        productId: order.id,
        productName: itemNames,
        category: 'order',
        imageUrl: order.items.isEmpty ? null : order.items.first.imageUrl,
        targetUserId: target,
        createdAt: DateTime.now(),
      ),
    );
  }

  Stream<List<AppNotification>> watchRecent({
    required String userId,
    int limit = 40,
  }) {
    final uid = userId.trim();
    if (uid.isEmpty) {
      return Stream.value(const <AppNotification>[]);
    }
    return _api.poll(() async {
      final data = await _api.getJson('/api/notifications');
      final raw = data['notifications'];
      if (raw is! List) return const <AppNotification>[];
      final list = raw
          .whereType<Map>()
          .map((m) => AppNotification.fromJson(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.take(limit).toList();
    });
  }

  Future<void> markAllSeen(String userId) async {
    await AuthService().markNotificationsSeen(userId);
  }
}
