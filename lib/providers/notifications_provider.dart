import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  final settings = ref.watch(appSettingsProvider);
  if (user == null) {
    return Stream.value(const <AppNotification>[]);
  }
  return ref.watch(notificationServiceProvider).watchRecent(userId: user.id).map((list) {
    return list.where((n) {
      final target = n.targetUserId?.trim() ?? '';
      if (target.isNotEmpty) {
        if (target != user.id) return false;
        return settings.allowsNotificationType(n.type, category: n.category);
      }
      // Discount broadcasts are customer offers, not shop-owner alerts.
      if (user.isShopOwner &&
          n.type == AppNotification.typeDiscountAssigned) {
        return false;
      }
      // Admin broadcasts — everyone (customers + shops).
      if (n.type == AppNotification.typeAdminAnnouncement) {
        return settings.allowsNotificationType(
          n.type,
          category: n.category,
        );
      }
      // Broadcast new products — hide from the shop that posted them.
      if (n.type == AppNotification.typeNewProduct &&
          n.shopOwnerId == user.id) {
        return false;
      }
      // Shop owners don't need the global product feed.
      if (user.isShopOwner && n.type == AppNotification.typeNewProduct) {
        return false;
      }
      return settings.allowsNotificationType(n.type, category: n.category);
    }).toList();
  });
});

/// Unread announcements for the current user.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  final settings = ref.watch(appSettingsProvider);
  if (user == null || !settings.notificationsEnabled) return 0;

  final list = ref.watch(notificationsProvider).valueOrNull ?? const [];
  final seenAt = user.lastNotificationsSeenAt;

  return list.where((n) {
    if (!settings.allowsNotificationType(n.type, category: n.category)) {
      return false;
    }
    if (seenAt == null) return true;
    return n.createdAt.isAfter(seenAt);
  }).length;
});

/// Shows a system banner for newly arrived inbox items while the app is alive.
final notificationLocalAlertBridgeProvider = Provider<void>((ref) {
  ref.listen(notificationsProvider, (previous, next) {
    final list = next.valueOrNull;
    if (list == null || list.isEmpty) return;
    // Skip the very first load so opening the app doesn't spam old alerts.
    if (previous?.valueOrNull == null) return;
    unawaited(PushNotificationService.instance.alertForNewInboxItems(list));
  });
});

final totalNotificationBadgeProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  var count = ref.watch(unreadNotificationsCountProvider);
  if (user?.hasUnreadApprovalNotice == true) count += 1;
  if (user?.isPending == true && count == 0) {
    // Keep a soft badge while pending approval with no product alerts.
    count = 1;
  }
  return count;
});
