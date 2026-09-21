import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_content_model.dart';
import '../models/app_notification.dart';
import '../models/banner_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';
import 'auth_provider.dart';
import 'notifications_provider.dart';

final adminServiceProvider = Provider((ref) => AdminService());

final pendingUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminServiceProvider).watchUsers(
        status: ApprovalStatus.pending,
      );
});

final allManagedUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminServiceProvider).watchUsers();
});

final adminBannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return ref.watch(adminServiceProvider).watchBanners();
});

final activeBannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return ref.watch(adminServiceProvider).watchBanners(activeOnly: true);
});

/// Live CMS doc for admin + customer (legal / support / home copy).
final appContentProvider = StreamProvider<AppContentModel>((ref) {
  return ref.watch(adminServiceProvider).watchAppContent();
});

/// Resolved content with baked-in defaults for empty fields.
final resolvedAppContentProvider = Provider<AppContentModel>((ref) {
  return ref.watch(appContentProvider).maybeWhen(
        data: (c) => c.withDefaults(),
        orElse: () => AppContentModel.defaults(),
      );
});

/// Recent admin broadcasts for the Content → ئاگاداری tab.
final adminAnnouncementsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const <AppNotification>[]);
  }
  return ref
      .watch(notificationServiceProvider)
      .watchRecent(userId: user.id, limit: 30)
      .map(
        (list) => list
            .where((n) => n.type == AppNotification.typeAdminAnnouncement)
            .toList(),
      );
});

final adminProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(adminServiceProvider).watchProducts();
});

final adminOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(adminServiceProvider).watchOrders();
});

final adminPendingOrdersProvider = Provider<List<OrderModel>>((ref) {
  return ref.watch(adminOrdersProvider).maybeWhen(
        data: (orders) =>
            orders.where((o) => o.status == OrderStatus.pending).toList(),
        orElse: () => const [],
      );
});

/// Cleared when admin opens the orders inbox / notifications sheet.
final adminPendingOrdersSeenAtProvider = StateProvider<DateTime?>((ref) => null);

/// Live count of pending orders (for screen copy / stats).
final adminPendingOrdersCountProvider = Provider<int>((ref) {
  return ref.watch(adminPendingOrdersProvider).length;
});

/// Badge count — only pending orders newer than last visit.
final adminUnseenPendingOrdersCountProvider = Provider<int>((ref) {
  final pending = ref.watch(adminPendingOrdersProvider);
  final seenAt = ref.watch(adminPendingOrdersSeenAtProvider);
  if (seenAt == null) return pending.length;
  return pending.where((o) {
    final stamp = o.lastStatusAt;
    return stamp.isAfter(seenAt);
  }).length;
});

void markAdminPendingOrdersSeen(WidgetRef ref) {
  ref.read(adminPendingOrdersSeenAtProvider.notifier).state = DateTime.now();
}
