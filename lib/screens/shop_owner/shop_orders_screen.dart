import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../../widgets/product_image.dart';

class ShopOrdersScreen extends ConsumerWidget {
  const ShopOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(shopOrdersProvider);
    final shopName = ref.watch(currentUserProvider)?.shopName ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'داواکارییەکان',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'داواکارییەکانی کڕیاران بۆ دووکانەکەت',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ordersAsync.when(
                loading: () => const LoadingView(),
                error: (_, _) => ErrorView(
                  message: 'هەڵە لە بارکردنی داواکارییەکان',
                  onRetry: () =>
                      ref.read(shopOrdersNotifierProvider.notifier).load(),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const EmptyView(
                      message: 'هێشتا هیچ داواکارییەک نییە',
                      icon: Icons.receipt_long_outlined,
                    );
                  }

                  final pending = orders
                      .where((o) => o.status == OrderStatus.pending)
                      .length;
                  final completed = orders
                      .where((o) => o.status == OrderStatus.completed)
                      .length;

                  return RefreshIndicator(
                    color: AppColors.secondary,
                    onRefresh: () =>
                        ref.read(shopOrdersNotifierProvider.notifier).load(),
                    child: ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'هەموو',
                                value: '${orders.length}',
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniStat(
                                label: 'چاوەڕوان',
                                value: '$pending',
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniStat(
                                label: 'تەواو',
                                value: '$completed',
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...orders.asMap().entries.map((entry) {
                          final index = entry.key;
                          final order = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child:
                                _ShopOrderCard(order: order, shopName: shopName)
                                    .animate()
                                    .fadeIn(delay: (40 * index).ms)
                                    .slideY(begin: 0.05),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: AppDecorations.card(radius: 18),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final String shopName;

  const _ShopOrderCard({required this.order, required this.shopName});

  @override
  ConsumerState<_ShopOrderCard> createState() => _ShopOrderCardState();
}

class _ShopOrderCardState extends ConsumerState<_ShopOrderCard> {
  bool _expanded = false;
  bool _busy = false;

  Future<void> _setStatus(OrderStatus status) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(shopOrdersNotifierProvider.notifier)
          .updateStatus(widget.order.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == OrderStatus.confirmed
                ? 'داواکاری قبوڵ کرا'
                : 'داواکاری ڕەتکرایەوە',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: status == OrderStatus.cancelled
              ? AppColors.error
              : AppColors.success,
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'نەتوانرا دۆخی داواکاری بگۆڕدرێت',
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shopItems = widget.shopName.isEmpty
        ? order.items
        : order.itemsForShop(widget.shopName);
    // Orders are per-shop; total already includes delivery fee.
    final shopTotal = order.total;

    final statusColor = switch (order.status) {
      OrderStatus.completed => AppColors.success,
      OrderStatus.pending => AppColors.warning,
      OrderStatus.confirmed => const Color(0xFFE67E22),
      OrderStatus.ready => AppColors.brand,
      OrderStatus.shipped => const Color(0xFF3B82F6),
      OrderStatus.cancelled => AppColors.error,
      OrderStatus.returned => const Color(0xFF8B5CF6),
    };

    return Container(
      decoration: AppDecorations.card(radius: 22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${Formatters.date(order.createdAt)} • #${order.id.substring(0, 6).toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          if ((order.deliveryAddress ?? '')
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              order.deliveryAddressLabel?.trim().isNotEmpty ==
                                      true
                                  ? '${order.deliveryAddressLabel}: ${order.deliveryAddress}'
                                  : order.deliveryAddress!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '${shopItems.fold(0, (s, i) => s + i.quantity)} بەرهەم',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.price(shopTotal),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 12),
                  Divider(color: AppColors.border.withValues(alpha: 0.7)),
                  const SizedBox(height: 8),
                  if (order.customerMeasurements.isNotEmpty) ...[
                    _CustomerMeasurementsCard(order: order),
                    const SizedBox(height: 12),
                  ],
                  if (order.deliveryFee > 0) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'گەیاندن · ${order.deliveryZoneLabel}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            Formatters.price(order.deliveryFee),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ...shopItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ProductImage(
                              path: item.imageUrl,
                              width: 44,
                              height: 44,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'قیاس: ${item.size} × ${item.quantity}',
                                  style: TextStyle(
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
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (order.status == OrderStatus.pending) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _setStatus(OrderStatus.cancelled),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('ڕەتکردنەوە'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _busy
                                ? null
                                : () => _setStatus(OrderStatus.confirmed),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(_busy ? '...' : 'قبوڵکردن'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (order.status == OrderStatus.confirmed) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => ref
                                .read(shopOrdersNotifierProvider.notifier)
                                .markReady(order),
                            icon: const Icon(Icons.inventory_rounded, size: 18),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brand,
                              foregroundColor: Colors.white,
                              disabledForegroundColor:
                                  Colors.white.withValues(alpha: 0.7),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            label: const Text('ئۆردەرەکە ئامادەیە'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerMeasurementsCard extends StatelessWidget {
  final OrderModel order;

  const _CustomerMeasurementsCard({required this.order});

  static String _number(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final m = order.customerMeasurements;
    final values = <(String, double?, String)>[
      ('باڵا', m.heightCm, 'سم'),
      ('کێش', m.weightKg, 'کگم'),
      ('شان', m.shoulderCm, 'سم'),
      ('سنگ', m.chestCm, 'سم'),
      ('کەمەر', m.waistCm, 'سم'),
      ('کەڵک', m.hipCm, 'سم'),
      ('قۆل', m.armLengthCm, 'سم'),
      ('قاچ', m.legLengthCm, 'سم'),
      ('مل', m.neckCm, 'سم'),
      ('پێڵاو', m.shoeSizeEu, 'EU'),
    ].where((entry) => entry.$2 != null).toList();
    final size =
        order.customerPreferredSize ?? order.customerMeasurements.suggestedSize;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.straighten_rounded,
                  size: 18,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قیاسەکانی کڕیار',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'جلێکی گونجاو بەو قیاسانە هەڵبژێرە',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (size != null && size.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    size,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                child: RichText(
                  textDirection: TextDirection.rtl,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: '${entry.$1}: '),
                      TextSpan(
                        text: '${_number(entry.$2!)} ${entry.$3}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
