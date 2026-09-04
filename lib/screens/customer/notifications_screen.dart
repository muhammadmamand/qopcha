import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/product_image.dart';

enum NotifCategory { all, orders, offers, wishlist, account, system }

enum NotifTone { teal, red, purple, blue, orange, green }

class _NotifItem {
  final String id;
  final NotifCategory category;
  final NotifTone tone;
  final IconData icon;
  final String title;
  final String body;
  final String timeLabel;
  final DateTime createdAt;
  final bool unread;
  final String? actionLabel;
  final String? imageUrl;
  final String? route;
  final bool couponPreview;
  final int bodyMaxLines;

  const _NotifItem({
    required this.id,
    required this.category,
    required this.tone,
    required this.icon,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.createdAt,
    this.unread = false,
    this.actionLabel,
    this.imageUrl,
    this.route,
    this.couponPreview = false,
    this.bodyMaxLines = 2,
  });
}

Color _toneColor(NotifTone tone) {
  // Dark mode needs lighter accents to stay readable on dark cards.
  final dark = AppColors.isDark;
  return switch (tone) {
    NotifTone.teal => dark ? const Color(0xFF2FA8B0) : const Color(0xFF146B72),
    NotifTone.red => dark ? const Color(0xFFFF7A7E) : const Color(0xFFE5484D),
    NotifTone.purple =>
      dark ? const Color(0xFF9F87FF) : const Color(0xFF7C5CFC),
    NotifTone.blue => dark ? const Color(0xFF6BA6FF) : const Color(0xFF3B82F6),
    NotifTone.orange => AppColors.highlight,
    NotifTone.green => dark ? const Color(0xFF4CC98D) : const Color(0xFF2D9B6A),
  };
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotifCategory _filter = NotifCategory.all;
  late Set<String> _readIds;

  @override
  void initState() {
    super.initState();
    _readIds = {};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).markNotificationsSeen();
    });
  }


  List<_NotifItem> _fromFirestore(
    List<AppNotification> list,
    DateTime? seenAt,
    String? userId,
  ) {
    return list.map((n) {
      final unread =
          (seenAt == null || n.createdAt.isAfter(seenAt)) &&
          !_readIds.contains(n.id);
      if (n.isAccountApproved) {
        return _NotifItem(
          id: n.id,
          category: NotifCategory.account,
          tone: NotifTone.green,
          icon: Icons.verified_rounded,
          title: n.title.isEmpty ? 'هەژمارەکەت پەسەند کرا' : n.title,
          body: n.body,
          timeLabel: _relativeKu(n.createdAt),
          createdAt: n.createdAt,
          unread: unread,
          actionLabel: 'باشە، تێگەیشتم',
        );
      }
      if (n.isOrderReady) {
        return _NotifItem(
          id: n.id,
          category: NotifCategory.orders,
          tone: NotifTone.green,
          icon: Icons.inventory_rounded,
          title: n.title.isEmpty ? 'داواکارییەکەت ئامادەیە' : n.title,
          body: n.body,
          timeLabel: _relativeKu(n.createdAt),
          createdAt: n.createdAt,
          unread: unread,
          actionLabel: 'بینینی داواکاری',
          imageUrl: n.imageUrl,
          route: '/orders',
        );
      }
      if (n.isOrderDelivered) {
        return _NotifItem(
          id: n.id,
          category: NotifCategory.orders,
          tone: NotifTone.green,
          icon: Icons.local_shipping_rounded,
          title: n.title.isEmpty ? 'کاڵاکە گەیشت' : n.title,
          body: n.body,
          timeLabel: _relativeKu(n.createdAt),
          createdAt: n.createdAt,
          unread: unread,
          actionLabel: 'بینینی داواکاری',
          imageUrl: n.imageUrl,
          route: '/orders?tab=delivered',
          bodyMaxLines: 8,
        );
      }
      if (n.isDiscountAssigned) {
        return _NotifItem(
          id: n.id,
          category: NotifCategory.offers,
          tone: NotifTone.red,
          icon: Icons.local_offer_rounded,
          title: n.title.isEmpty ? 'داشکاندنی نوێ' : n.title,
          body: n.body,
          timeLabel: _relativeKu(n.createdAt),
          createdAt: n.createdAt,
          unread: unread,
          actionLabel: n.productId.isNotEmpty
              ? 'بینینی بەرهەم'
              : 'بینینی داشکاندنەکان',
          imageUrl: n.imageUrl,
          route: n.productId.isNotEmpty
              ? '/product/${n.productId}'
              : '/discounts',
        );
      }
      if (n.isAdminAnnouncement) {
        return _NotifItem(
          id: n.id,
          category: NotifCategory.system,
          tone: NotifTone.teal,
          icon: Icons.campaign_rounded,
          title: n.title.isEmpty ? 'ئاگاداری قۆپچە' : n.title,
          body: n.body,
          timeLabel: _relativeKu(n.createdAt),
          createdAt: n.createdAt,
          unread: unread,
          actionLabel: 'باشە',
        );
      }
      return _NotifItem(
        id: n.id,
        category: NotifCategory.offers,
        tone: NotifTone.teal,
        icon: Icons.shopping_bag_rounded,
        title: n.title.isEmpty ? 'بەرهەمی نوێ' : n.title,
        body: n.body,
        timeLabel: _relativeKu(n.createdAt),
        createdAt: n.createdAt,
        unread: unread && n.shopOwnerId != userId,
        actionLabel: 'بینینی بەرهەم',
        imageUrl: n.imageUrl,
        route: n.productId.isNotEmpty ? '/product/${n.productId}' : null,
      );
    }).toList();
  }

  static String _relativeKu(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'ئێستا';
    if (diff.inMinutes < 60) return '${diff.inMinutes} خولەک پێش';
    if (diff.inHours < 24 && now.day == dt.day) {
      return '${diff.inHours} کاتژمێر پێش';
    }
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = h < 12 ? 'بەیانی' : 'ئێوارە';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return 'دوێنێ، $h12:$m $period';
    }
    if (diff.inDays < 7) return '${diff.inDays} ڕۆژ پێش';
    return '${dt.year}/${dt.month}/${dt.day}';
  }

  String _sectionFor(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return 'ئەمڕۆ';
    if (day == today.subtract(const Duration(days: 1))) return 'دوێنێ';
    return 'ئەم هەفتەیە';
  }

  void _markAllRead(List<_NotifItem> items) {
    HapticFeedback.lightImpact();
    setState(() {
      _readIds = {..._readIds, ...items.map((e) => e.id)};
    });
    ref.read(authProvider.notifier).markNotificationsSeen();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'هەموو وەک خوێندراوە نیشانکران',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brand,
      ),
    );
  }

  void _onAction(_NotifItem item) {
    if (item.id == 'account-approved') {
      ref.read(authProvider.notifier).markApprovalNoticeSeen();
      setState(() => _readIds.add(item.id));
      return;
    }
    if (item.actionLabel == 'کۆپی کۆد') {
      Clipboard.setData(const ClipboardData(text: 'SAVE20'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'کۆد کۆپی کرا: SAVE20',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.brand,
        ),
      );
      return;
    }
    final route = item.route;
    if (route != null && route.isNotEmpty) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the theme changes so AppColors are re-read.
    ref.watch(appSettingsProvider.select((s) => s.themeMode));
    final user = ref.watch(currentUserProvider);
    final async = ref.watch(notificationsProvider);
    final live = async.valueOrNull ?? const <AppNotification>[];
    final fromLive = _fromFirestore(
      live,
      user?.lastNotificationsSeenAt,
      user?.id,
    );
    final accountExtra = <_NotifItem>[];
    final now = DateTime.now();
    if (user?.hasUnreadApprovalNotice == true) {
      accountExtra.add(
        _NotifItem(
          id: 'account-approved',
          category: NotifCategory.account,
          tone: NotifTone.green,
          icon: Icons.verified_rounded,
          title: user?.isShopOwner == true
              ? 'دووکانەکەت پەسەند کرا'
              : 'هەژمارەکەت پەسەند کرا',
          body: user?.isShopOwner == true
              ? 'ئێستا دەتوانیت بەرهەم زیاد بکەیت و فرۆش بکەیت.'
              : 'ئێستا دەتوانیت داواکاری بکەیت و بە تەواوی ئەپ بەکاربهێنیت.',
          timeLabel: 'ئێستا',
          createdAt: now,
          unread: !_readIds.contains('account-approved'),
          actionLabel: 'باشە، تێگەیشتم',
        ),
      );
    } else if (user?.isPending == true) {
      accountExtra.add(
        _NotifItem(
          id: 'account-pending',
          category: NotifCategory.account,
          tone: NotifTone.orange,
          icon: Icons.hourglass_top_rounded,
          title: 'چاوەڕوانی پەسەندکردن',
          body:
              'دەتوانیت بەرهەمەکان ببینیت، بەڵام ناتوانیت داواکاری بکەیت تا ئەدمین پەسەندی بکات.',
          timeLabel: 'چاوەڕوان',
          createdAt: now.subtract(const Duration(minutes: 30)),
          unread: !_readIds.contains('account-pending'),
        ),
      );
    }
    final combined = [...accountExtra, ...fromLive]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Deduplicate by id; live wins
    final seen = <String>{};
    final all = <_NotifItem>[];
    for (final n in combined) {
      if (seen.add(n.id)) {
        final read = _readIds.contains(n.id);
        all.add(
          read
              ? _NotifItem(
                  id: n.id,
                  category: n.category,
                  tone: n.tone,
                  icon: n.icon,
                  title: n.title,
                  body: n.body,
                  timeLabel: n.timeLabel,
                  createdAt: n.createdAt,
                  unread: false,
                  actionLabel: n.actionLabel,
                  imageUrl: n.imageUrl,
                  route: n.route,
                  couponPreview: n.couponPreview,
                )
              : n,
        );
      }
    }

    final filtered = _filter == NotifCategory.all
        ? all
        : all.where((n) => n.category == _filter).toList();
    final unreadCount = all.where((n) => n.unread).length;

    final sections = <String, List<_NotifItem>>{};
    for (final n in filtered) {
      final key = _sectionFor(n.createdAt);
      sections.putIfAbsent(key, () => []).add(n);
    }
    const order = ['ئەمڕۆ', 'دوێنێ', 'ئەم هەفتەیە'];
    final sectionKeys = [
      ...order.where(sections.containsKey),
      ...sections.keys.where((k) => !order.contains(k)),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                unreadCount: unreadCount,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                onMarkAll: () => _markAllRead(all),
                onMore: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: AppColors.sheet,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (_) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(
                                  Icons.done_all_rounded,
                                  color: AppColors.brand,
                                ),
                                title: Text(
                                  'هەموو وەک خوێندراوە',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _markAllRead(all);
                                },
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.settings_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                title: Text(
                                  'ڕێکخستنی ئاگاداری',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push('/settings');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _CategoryChips(
                selected: _filter,
                onChanged: (c) => setState(() => _filter = c),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: async.isLoading && live.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        itemCount: sectionKeys.length,
                        itemBuilder: (context, i) {
                          final key = sectionKeys[i];
                          final items = sections[key]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  top: i == 0 ? 4 : 18,
                                  bottom: 12,
                                  right: 4,
                                ),
                                child: Text(
                                  key,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              ...items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _NotificationCard(
                                    item: item,
                                    onTap: () {
                                      setState(() => _readIds.add(item.id));
                                      _onAction(item);
                                    },
                                    onAction: () {
                                      setState(() => _readIds.add(item.id));
                                      _onAction(item);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onBack;
  final VoidCallback onMarkAll;
  final VoidCallback onMore;

  const _Header({
    required this.unreadCount,
    required this.onBack,
    required this.onMarkAll,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              _RoundBtn(icon: Icons.arrow_forward_ios_rounded, onTap: onBack),
              const Spacer(),
              _RoundBtn(icon: Icons.more_horiz_rounded, onTap: onMore),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ئاگادارییەکان',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '• $unreadCount نوێ',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: onMarkAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'هەموو وەک خوێندراوە',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppColors.isDark ? 0.24 : 0.06,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  final NotifCategory selected;
  final ValueChanged<NotifCategory> onChanged;

  const _CategoryChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final items = [
      (NotifCategory.all, s.all, Icons.apps_rounded),
      (NotifCategory.orders, s.notifOrders, Icons.inventory_2_outlined),
      (NotifCategory.offers, s.notifOffers, Icons.local_offer_outlined),
      (NotifCategory.wishlist, s.notifWishlist, Icons.favorite_border_rounded),
      (NotifCategory.account, s.notifAccount, Icons.person_outline_rounded),
      (NotifCategory.system, s.notifSystem, Icons.notifications_none_rounded),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final active = item.$1 == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(item.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active ? AppColors.brand : AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active
                      ? AppColors.brand
                      : AppColors.border.withValues(alpha: 0.8),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    item.$3,
                    size: 16,
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotifItem item;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(item.tone);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppColors.isDark ? 0.22 : 0.05,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread dot + icon (start = right in RTL)
                Column(
                  children: [
                    if (item.unread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 16),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: color, size: 24),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.timeLabel,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.body,
                        maxLines: item.bodyMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.actionLabel != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: onAction,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: color,
                                side: BorderSide(
                                  color: color.withValues(alpha: 0.45),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(0, 34),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                item.actionLabel!,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (item.couponPreview)
                              _CouponThumb(color: color)
                            else if (item.imageUrl != null &&
                                item.imageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: isNetworkImagePath(item.imageUrl!)
                                      ? CachedNetworkImage(
                                          imageUrl: item.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) => Container(
                                            color: AppColors.surfaceVariant,
                                          ),
                                        )
                                      : ProductImage(
                                          path: item.imageUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ] else if (item.imageUrl != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponThumb extends StatelessWidget {
  final Color color;
  const _CouponThumb({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.4),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: color.withValues(alpha: 0.5)),
        child: Center(
          child: Text(
            '٢٠٪',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          const Radius.circular(11),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = dist + dash;
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final brand = AppColors.brand;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brand.withValues(alpha: dark ? 0.28 : 0.18),
                    brand.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: brand.withValues(alpha: 0.22),
                ),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 46,
                color: brand,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'هیچ ئاگادارییەک نییە',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'کاتێک داواکاری، ئۆفەر، یان نوێکارییەک هەبێت،\nنوێترین ئاگادارییەکان لێرە دەردەکەون',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.5,
                height: 1.55,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: brand.withValues(alpha: dark ? 0.16 : 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: brand.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.autorenew_rounded, size: 16, color: brand),
                  const SizedBox(width: 8),
                  Text(
                    'چاوەڕوانی نوێترین ئاگادارییەکان',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: brand,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
