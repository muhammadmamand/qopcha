import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart_item.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/shell_navigation_provider.dart';
import '../../widgets/order_preparing_animation.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../../widgets/product_image.dart';

enum _OrderFilter {
  pending,
  confirmed,
  ready,
  shipped,
  delivered,
  returned,
}

class OrdersScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const OrdersScreen({super.key, this.initialTab});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  _OrderFilter _filter = _OrderFilter.pending;
  bool _pickedInitialTab = false;
  String? _markingTab;

  @override
  void initState() {
    super.initState();
    final initial = _filterFromName(widget.initialTab);
    if (initial != null) {
      _filter = initial;
      _pickedInitialTab = true;
    }
  }

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab == oldWidget.initialTab) return;
    final next = _filterFromName(widget.initialTab);
    if (next == null) return;
    _filter = next;
    _pickedInitialTab = true;
  }

  static _OrderFilter? _filterFromName(String? name) {
    return switch (name) {
      'pending' => _OrderFilter.pending,
      'confirmed' => _OrderFilter.confirmed,
      'ready' => _OrderFilter.ready,
      'shipped' => _OrderFilter.shipped,
      'delivered' => _OrderFilter.delivered,
      'returned' => _OrderFilter.returned,
      _ => null,
    };
  }

  List<OrderModel> _filteredBy(List<OrderModel> orders, _OrderFilter filter) {
    return switch (filter) {
      _OrderFilter.pending =>
        orders.where((o) => o.status == OrderStatus.pending).toList(),
      _OrderFilter.confirmed =>
        orders.where((o) => o.status == OrderStatus.confirmed).toList(),
      _OrderFilter.ready =>
        orders.where((o) => o.status == OrderStatus.ready).toList(),
      _OrderFilter.shipped =>
        orders.where((o) => o.status == OrderStatus.shipped).toList(),
      _OrderFilter.delivered =>
        orders.where((o) => o.status == OrderStatus.completed).toList(),
      _OrderFilter.returned =>
        orders.where((o) => o.status == OrderStatus.returned).toList(),
    };
  }

  List<OrderModel> _filtered(List<OrderModel> orders) =>
      _filteredBy(orders, _filter);

  void _pickInitialTab(List<OrderModel> orders) {
    if (_pickedInitialTab || orders.isEmpty) return;
    _pickedInitialTab = true;
    for (final filter in _OrderFilter.values) {
      if (_filteredBy(orders, filter).isNotEmpty) {
        _filter = filter;
        return;
      }
    }
  }

  static String _tabKey(_OrderFilter filter) => switch (filter) {
    _OrderFilter.pending => 'pending',
    _OrderFilter.confirmed => 'confirmed',
    _OrderFilter.ready => 'ready',
    _OrderFilter.shipped => 'shipped',
    _OrderFilter.delivered => 'delivered',
    _OrderFilter.returned => 'returned',
  };

  static List<String> _keysToMark(_OrderFilter filter) => switch (filter) {
    _OrderFilter.confirmed => const ['confirmed', 'ready'],
    _ => [_tabKey(filter)],
  };

  void _markCurrentTabSeen() {
    final keys = _keysToMark(_filter);
    final markId = keys.join(',');
    if (_markingTab == markId) return;
    final counts = ref.read(unseenOrderTabCountsProvider);
    final unread = keys.where((key) => (counts[key] ?? 0) > 0).toList();
    if (unread.isEmpty) return;
    _markingTab = markId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        if (_keysToMark(_filter).join(',') != markId) return;
        await ref.read(authProvider.notifier).markOrderTabsSeen(unread);
      } finally {
        if (_markingTab == markId) _markingTab = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: AppColors.brand.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 18),
                Text(
                  'داواکارییەکان',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'بۆ بینینی داواکارییەکانت پێویستە بچیتە ژوورەوە.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => context.push('/auth?next=/orders'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'چوونەژوورەوە',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'گەڕانەوە بۆ سەرەکی',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final orders = ref.watch(ordersProvider);
    _pickInitialTab(orders);
    _markCurrentTabSeen();
    final visible = _filtered(orders);
    final unseen = ref.watch(unseenOrderTabCountsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: _OrdersHeader(
                orderCount: orders.length,
                onBack: () {
                  HapticFeedback.selectionClick();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
              ),
            ),
            _StatusTabs(
              selected: _filter,
              counts: {
                for (final f in _OrderFilter.values)
                  f: unseen[_tabKey(f)] ?? 0,
              },
              onSelected: (f) {
                HapticFeedback.selectionClick();
                setState(() => _filter = f);
              },
            ),
            const SizedBox(height: 6),
            Expanded(
              child: visible.isEmpty
                  ? _OrdersEmpty(
                      hasAnyOrders: orders.isNotEmpty,
                      onBrowse: () => context.go('/home'),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        10,
                        16,
                        kPremiumBottomNavClearance + 16,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _OrderCard(order: visible[index])
                            .animate()
                            .fadeIn(delay: (35 * index).ms, duration: 350.ms)
                            .slideY(begin: 0.04, curve: Curves.easeOutCubic);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  final int orderCount;
  final VoidCallback onBack;

  const _OrdersHeader({
    required this.orderCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final theme = AppColors.colorTheme;
    final brand = AppColors.brand;
    final ink = dark ? const Color(0xFFF3F7F7) : const Color(0xFF121215);
    // Same tint family as PremiumBottomNav — frosted glass via BackdropFilter
    // (LiquidGlassLens can't refract inside scaffold body on Skia/Windows).
    final glassTint = dark
        ? (theme.isFloral
            ? Color.alphaBlend(
                brand.withValues(alpha: 0.22),
                const Color(0x99181C1E),
              )
            : const Color(0x99181C1E))
        : (theme.isFloral
            ? Color.alphaBlend(
                brand.withValues(alpha: 0.16),
                const Color(0xB8FFFFFF),
              )
            : const Color(0xB8FFFFFF));
    final rim = dark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.72);
    const radius = 24.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: (theme.isFloral ? brand : Colors.black)
                .withValues(alpha: dark ? 0.22 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: glassTint,
              border: Border.all(color: rim, width: 0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onBack,
                    tooltip: 'گەڕانەوە',
                    style: IconButton.styleFrom(
                      backgroundColor: dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      foregroundColor: ink,
                      side: BorderSide(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: brand.withValues(alpha: dark ? 0.28 : 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: brand.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: brand,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'داواکارییەکان',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                            height: 1.2,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          orderCount == 0
                              ? 'شوێنپێی داواکارییەکانت بگرە'
                              : '$orderCount داواکاری · شوێنپێی بکە',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: dark
                                ? Colors.white.withValues(alpha: 0.62)
                                : const Color(0xFF5C5C66),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (orderCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: brand.withValues(alpha: dark ? 0.28 : 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: brand.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        '$orderCount',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: brand,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final _OrderFilter selected;
  final Map<_OrderFilter, int> counts;
  final ValueChanged<_OrderFilter> onSelected;

  const _StatusTabs({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  static const _tabs = <(_OrderFilter, String, IconData)>[
    (_OrderFilter.pending, 'چاوەڕوان', Icons.schedule_rounded),
    (_OrderFilter.confirmed, 'قبوڵکراو', Icons.verified_rounded),
    (_OrderFilter.ready, 'ئامادەیە', Icons.inventory_rounded),
    (_OrderFilter.shipped, 'نێردراو', Icons.local_shipping_outlined),
    (_OrderFilter.delivered, 'گەیشتوو', Icons.check_circle_outline_rounded),
    (_OrderFilter.returned, 'گەڕاوە', Icons.replay_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label, icon) = _tabs[index];
          final active = filter == selected;
          final count = counts[filter] ?? 0;

          return GestureDetector(
            onTap: () => onSelected(filter),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active ? AppColors.brand : AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? AppColors.brand
                      : AppColors.border.withValues(alpha: 0.8),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter == _OrderFilter.shipped)
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        active || AppColors.isDark
                            ? Colors.white
                            : AppColors.textTertiary,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/images/car.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    Icon(
                      icon,
                      size: 16,
                      color: active ? Colors.white : AppColors.textTertiary,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.22)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: active
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrdersEmpty extends StatelessWidget {
  final bool hasAnyOrders;
  final VoidCallback onBrowse;

  const _OrdersEmpty({required this.hasAnyOrders, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: 0.18),
                    AppColors.brand.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Icon(
                hasAnyOrders
                    ? Icons.filter_list_rounded
                    : Icons.receipt_long_rounded,
                size: 42,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasAnyOrders
                  ? 'هیچ داواکارییەک لەم بەشەدا نییە'
                  : 'هێشتا داواکاری نییە',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasAnyOrders
                  ? 'فلتەرێکی تر هەڵبژێرە یان داواکاری نوێ بکە'
                  : 'کاتێک کڕینەکەت تەواو دەکەیت،\nداواکارییەکانت لێرە دەبینیت',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (!hasAnyOrders) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onBrowse,
                  icon: const Icon(Icons.storefront_rounded, size: 18),
                  label: const Text('گەڕان بۆ بەرهەمەکان'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  Color get _statusColor => switch (order.status) {
    OrderStatus.completed => const Color(0xFF2D9B6A),
    OrderStatus.shipped => const Color(0xFF3B82F6),
    OrderStatus.ready => AppColors.brand,
    OrderStatus.confirmed => const Color(0xFFE67E22),
    OrderStatus.pending => const Color(0xFFD4A017),
    OrderStatus.cancelled => AppColors.error,
    OrderStatus.returned => const Color(0xFF8B5CF6),
  };

  IconData get _statusIcon => switch (order.status) {
    OrderStatus.completed => Icons.check_circle_rounded,
    OrderStatus.shipped => Icons.local_shipping_rounded,
    OrderStatus.ready => Icons.inventory_rounded,
    OrderStatus.confirmed => Icons.verified_rounded,
    OrderStatus.pending => Icons.schedule_rounded,
    OrderStatus.cancelled => Icons.replay_rounded,
    OrderStatus.returned => Icons.assignment_return_rounded,
  };

  void _showDetails(BuildContext context, WidgetRef ref) {
    showAppModalBottomSheet<void>(
      context: context,
      ref: ref,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'وردەکاری داواکاری #${order.shortId}',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Formatters.dateTime(order.createdAt),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (order.status == OrderStatus.confirmed) ...[
                  const SizedBox(height: 14),
                  OrderPreparingAnimation(shopName: order.shopName),
                ],
                if (order.status == OrderStatus.returned &&
                    (order.returnReason?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هۆکاری گەڕاندنەوە',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.returnReason!,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (order.returnNote?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(
                            order.returnNote!,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: order.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _DetailItemRow(item: order.items[i]),
                  ),
                ),
                const SizedBox(height: 14),
                if (order.deliveryFee > 0) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'گەیاندن · ${order.deliveryZoneLabel}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        Formatters.price(order.deliveryFee),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'کۆی کاڵاکان',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.price(order.itemsSubtotal),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Text(
                      'کۆی گشتی',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.price(order.grandTotal),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _primaryAction(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    switch (order.status) {
      case OrderStatus.completed:
        for (final item in order.items) {
          await ref.read(cartProvider.notifier).addCartItem(item);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'بەرهەمەکان زیادکرانە سەبەتە',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/cart');
        }
      case OrderStatus.shipped:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'داواکارییەکە لە ڕێگادایە — بەمزووانە دەگات',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      case OrderStatus.ready:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'داواکارییەکەت ئامادەیە — بەمزووانە دەگاتە دەستت',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.brand,
            ),
          );
        }
      case OrderStatus.confirmed:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'داواکاریەکەت لە لایەن دووکانەوە قبوڵ کرا — ئامادە دەکرێت',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.brand,
            ),
          );
        }
      case OrderStatus.pending:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'پارەدان لە کاتی گەیاندن — چاوەڕوانی قبوڵکردنی دووکان',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      case OrderStatus.cancelled:
        for (final item in order.items) {
          await ref.read(cartProvider.notifier).addCartItem(item);
        }
        if (context.mounted) context.go('/cart');
      case OrderStatus.returned:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                order.returnReason?.trim().isNotEmpty == true
                    ? 'گەڕاوەتەوە: ${order.returnReason}'
                    : 'ئەم داواکارییە گەڕێنراوەتەوە',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
    }
  }

  Future<void> _showReturnSheet(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final result = await showAppModalBottomSheet<({String reason, String note})>(
      context: context,
      ref: ref,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ReturnReasonSheet(order: order),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref.read(ordersProvider.notifier).requestReturn(
            order.id,
            reason: result.reason,
            note: result.note,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'داواکاری گەڕاندنەوە نێردرا',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.brand,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            kPremiumBottomNavClearance,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            kPremiumBottomNavClearance,
          ),
        ),
      );
    }
  }

  /// Only these states give the customer something real to do; the rest are
  /// informational, so their button stays tonal instead of solid.
  bool get _isActionable =>
      order.status == OrderStatus.completed ||
      order.status == OrderStatus.cancelled;

  Color get _actionColor =>
      order.status == OrderStatus.cancelled ? AppColors.brand : _statusColor;

  (String, IconData) get _primaryBtn {
    return switch (order.status) {
      OrderStatus.completed => ('دووبارە بکڕە', Icons.refresh_rounded),
      OrderStatus.shipped => ('شوێنکەوتن', Icons.location_on_outlined),
      OrderStatus.ready => ('ئامادەیە', Icons.inventory_rounded),
      OrderStatus.confirmed => ('ئامادە دەکرێت', Icons.checkroom_rounded),
      OrderStatus.pending => ('چاوەڕوان', Icons.schedule_rounded),
      OrderStatus.cancelled => ('دووبارە داواکاری', Icons.replay_rounded),
      OrderStatus.returned => ('گەڕاوەتەوە', Icons.assignment_return_rounded),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (btnLabel, btnIcon) = _primaryBtn;
    final actionColor = _actionColor;

    return Material(
      color: AppColors.card,
      elevation: 0,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => _showDetails(context, ref),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppColors.isDark ? 0.24 : 0.04,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.shortId}',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.dateTime(order.createdAt),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.5,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(
                    label: order.statusLabel,
                    icon: _statusIcon,
                    imageAsset: order.status == OrderStatus.shipped
                        ? 'assets/images/car.png'
                        : null,
                    color: _statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _OrderProgress(
                status: order.status,
                color: _statusColor,
                detail: order.statusDetail,
              ),
              if (order.status == OrderStatus.confirmed) ...[
                const SizedBox(height: 12),
                OrderPreparingAnimation(
                  shopName: order.shopName,
                  compact: true,
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(
                    alpha: AppColors.isDark ? 0.55 : 0.75,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _OrderThumbs(items: order.items),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.itemCount} بەرهەم',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'پارەدان لە کاتی گەیاندن',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.price(order.grandTotal),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showDetails(context, ref),
                      icon: const Icon(Icons.description_outlined, size: 16),
                      label: Text(
                        'وردەکاری',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        backgroundColor: AppColors.surfaceVariant.withValues(
                          alpha: AppColors.isDark ? 0.6 : 0.9,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _primaryAction(context, ref),
                      icon: Icon(btnIcon, size: 16),
                      label: Text(
                        btnLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _isActionable
                            ? Colors.white
                            : actionColor,
                        backgroundColor: _isActionable
                            ? actionColor
                            : actionColor.withValues(alpha: 0.14),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (order.canRequestReturn) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showReturnSheet(context, ref),
                    icon: const Icon(Icons.assignment_return_outlined, size: 18),
                    label: Text(
                      'گەڕاندنەوەی کاڵا',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B5CF6),
                      side: BorderSide(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
              if (order.status == OrderStatus.returned &&
                  (order.returnReason?.trim().isNotEmpty ?? false)) ...[
                const SizedBox(height: 10),
                Text(
                  'هۆکار: ${order.returnReason}',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? imageAsset;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.icon,
    this.imageAsset,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageAsset != null)
            ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: Image.asset(
                imageAsset!,
                width: 14,
                height: 14,
                fit: BoxFit.contain,
              ),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Five-segment bar showing how far the order has moved through fulfilment.
class _OrderProgress extends StatelessWidget {
  final OrderStatus status;
  final Color color;
  final String detail;

  const _OrderProgress({
    required this.status,
    required this.color,
    required this.detail,
  });

  int get _step => switch (status) {
    OrderStatus.pending => 1,
    OrderStatus.confirmed => 2,
    OrderStatus.ready => 3,
    OrderStatus.shipped => 4,
    OrderStatus.completed => 5,
    OrderStatus.cancelled => 0,
    OrderStatus.returned => 0,
  };

  @override
  Widget build(BuildContext context) {
    final cancelled = status == OrderStatus.cancelled ||
        status == OrderStatus.returned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cancelled)
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          )
        else
          Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < _step
                          ? color
                          : AppColors.border.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 7),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _OrderThumbs extends StatelessWidget {
  final List<CartItem> items;

  const _OrderThumbs({required this.items});

  static const _size = 44.0;
  static const _step = 30.0;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(3).toList();
    final extra = items.length - visible.length;
    final slots = visible.length + (extra > 0 ? 1 : 0);

    return SizedBox(
      height: _size,
      width: slots == 0 ? _size : _size + (slots - 1) * _step,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * _step,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: AppColors.card,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: ProductImage(
                    path: visible[i].imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: visible.length * _step,
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: AppColors.brand.withValues(alpha: 0.14),
                  border: Border.all(color: AppColors.card, width: 2),
                ),
                child: Text(
                  '+$extra',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailItemRow extends StatelessWidget {
  final CartItem item;

  const _DetailItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ProductImage(
            path: item.imageUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.shopName} · ${item.size} × ${item.quantity}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Text(
          Formatters.price(item.lineTotal),
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ReturnReasonSheet extends StatefulWidget {
  final OrderModel order;

  const _ReturnReasonSheet({required this.order});

  @override
  State<_ReturnReasonSheet> createState() => _ReturnReasonSheetState();
}

class _ReturnReasonSheetState extends State<_ReturnReasonSheet> {
  String? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final other = _reason == 'هۆکاری تر';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'گەڕاندنەوەی کاڵا #${widget.order.shortId}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'هۆکاری گەڕاندنەوە هەڵبژێرە',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.42,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final reason in OrderReturnReasons.presets) ...[
                    Material(
                      color: _reason == reason
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                          : AppColors.surfaceVariant.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _reason = reason),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _reason == reason
                                  ? const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.5)
                                  : AppColors.border.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _reason == reason
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                size: 20,
                                color: _reason == reason
                                    ? const Color(0xFF8B5CF6)
                                    : AppColors.textTertiary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (other) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: _note,
                      maxLines: 3,
                      maxLength: 500,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'هۆکارەکەت بنووسە…',
                        hintStyle: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _reason == null
                    ? null
                    : () {
                        final note = other ? _note.text.trim() : '';
                        if (other && note.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تکایە هۆکارەکەت بنووسە',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, (reason: _reason!, note: note));
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'ناردنی داواکاری گەڕاندنەوە',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
