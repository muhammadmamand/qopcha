import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/admin_sales_rankings.dart';
import '../../core/utils/formatters.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import 'admin_shell.dart';

/// Dedicated admin page: top buyers & top shops + personal VIP discounts.
class AdminLeadersScreen extends ConsumerWidget {
  const AdminLeadersScreen({super.key});

  Future<void> _openCustomerDiscount(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required String name,
    UserModel? user,
  }) async {
    HapticFeedback.selectionClick();
    final result = await showModalBottomSheet<_SpecialDiscountDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CustomerSpecialDiscountSheet(
        customerName: name,
        initialProductPercent: user?.productDiscountPercent ?? 0,
        initialDeliveryPercent: user?.deliveryDiscountPercent ?? 0,
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref.read(adminServiceProvider).setCustomerSpecialDiscount(
            userId: userId,
            productDiscountPercent: result.productPercent,
            deliveryDiscountPercent: result.deliveryPercent,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.productPercent <= 0 && result.deliveryPercent <= 0
                ? 'داشکانی تایبەتی $name لابرا'
                : 'داشکانی تایبەت بۆ $name پاشەکەوت کرا',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.brand,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'نەتوانرا داشکان پاشەکەوت بکرێت',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final usersAsync = ref.watch(allManagedUsersProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeader(
            title: 'باشترینەکان',
            subtitle: 'ڕیزبەندی + داشکانی تایبەت بۆ کڕیار',
            onLogout: () => ref.read(authProvider.notifier).logout(),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'هەڵە لە بارکردنی ڕیزبەندی',
                onRetry: () => ref.invalidate(adminOrdersProvider),
              ),
              data: (orders) {
                final users = usersAsync.valueOrNull ?? const [];
                final byId = {for (final u in users) u.id: u};
                final buyers = AdminSalesRankings.topCustomers(
                  orders,
                  users: users,
                  limit: 20,
                );
                final shops = AdminSalesRankings.topShops(orders, limit: 20);

                return RefreshIndicator(
                  color: AppColors.brand,
                  onRefresh: () async {
                    ref.invalidate(adminOrdersProvider);
                    ref.invalidate(allManagedUsersProvider);
                  },
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    children: [
                      _SectionTitle(
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.brand,
                        title: 'زۆرترین کڕین',
                        subtitle: 'کرتە بکە بۆ داشکانی جل یان کرێی گەیاندن',
                      ),
                      const SizedBox(height: 10),
                      _BuyerLeaderList(
                        color: AppColors.brand,
                        emptyText: 'هێشتا کڕینێکی تۆمارکراو نییە',
                        buyers: buyers,
                        usersById: byId,
                        onTapBuyer: (buyer) => _openCustomerDiscount(
                          context,
                          ref,
                          userId: buyer.userId,
                          name: buyer.name,
                          user: byId[buyer.userId],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SectionTitle(
                        icon: Icons.storefront_rounded,
                        color: AppColors.highlight,
                        title: 'زۆرترین فرۆش',
                        subtitle: 'دووکانەکان بەپێی کۆی فرۆشی کاڵا',
                      ),
                      const SizedBox(height: 10),
                      _LeaderList(
                        color: AppColors.highlight,
                        emptyText: 'هێشتا فرۆشێکی تۆمارکراو نییە',
                        rows: [
                          for (final s in shops)
                            (
                              s.shopName,
                              '${s.orderCount} داواکاری · ${s.itemCount} بەرهەم',
                              Formatters.price(s.totalSales),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'تێبینی: داواکاریی چاوەڕوان و ڕەتکراو لە ڕیزبەندیدا نابن. داشکانی تایبەت تەنها بۆ کڕیارەکانە.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialDiscountDraft {
  final double productPercent;
  final double deliveryPercent;

  const _SpecialDiscountDraft({
    required this.productPercent,
    required this.deliveryPercent,
  });
}

class _CustomerSpecialDiscountSheet extends StatefulWidget {
  final String customerName;
  final double initialProductPercent;
  final double initialDeliveryPercent;

  const _CustomerSpecialDiscountSheet({
    required this.customerName,
    required this.initialProductPercent,
    required this.initialDeliveryPercent,
  });

  @override
  State<_CustomerSpecialDiscountSheet> createState() =>
      _CustomerSpecialDiscountSheetState();
}

class _CustomerSpecialDiscountSheetState
    extends State<_CustomerSpecialDiscountSheet> {
  late double _productPercent;
  late double _deliveryPercent;

  @override
  void initState() {
    super.initState();
    _productPercent = widget.initialProductPercent.clamp(0, 70);
    _deliveryPercent = widget.initialDeliveryPercent.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'داشکانی تایبەت',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.customerName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _DiscountSliderBlock(
            icon: Icons.checkroom_rounded,
            color: AppColors.brand,
            title: 'داشکان لە نرخی جل و بەرگ',
            subtitle: 'بۆ هەموو کاڵاکان لە کاتی کڕیندا',
            value: _productPercent,
            max: 70,
            onChanged: (v) => setState(() => _productPercent = v),
          ),
          const SizedBox(height: 14),
          _DiscountSliderBlock(
            icon: Icons.local_shipping_outlined,
            color: AppColors.highlight,
            title: 'داشکان لە کرێی گەیاندن',
            subtitle: 'کاتێک ئەدمین ناوچە دیاری دەکات',
            value: _deliveryPercent,
            max: 100,
            onChanged: (v) => setState(() => _deliveryPercent = v),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    const _SpecialDiscountDraft(
                      productPercent: 0,
                      deliveryPercent: 0,
                    ),
                  ),
                  child: const Text('لابردن'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _SpecialDiscountDraft(
                      productPercent: _productPercent,
                      deliveryPercent: _deliveryPercent,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                  ),
                  child: const Text('پاشەکەوت'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscountSliderBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  const _DiscountSliderBlock({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.18),
              overlayColor: color.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: value.clamp(0, max),
              min: 0,
              max: max,
              divisions: max.round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BuyerLeaderList extends StatelessWidget {
  final Color color;
  final String emptyText;
  final List<CustomerPurchaseRank> buyers;
  final Map<String, UserModel> usersById;
  final ValueChanged<CustomerPurchaseRank> onTapBuyer;

  const _BuyerLeaderList({
    required this.color,
    required this.emptyText,
    required this.buyers,
    required this.usersById,
    required this.onTapBuyer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(radius: 18),
      child: buyers.isEmpty
          ? Text(
              emptyText,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < buyers.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: AppColors.border.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _BuyerRow(
                    rank: i + 1,
                    color: color,
                    buyer: buyers[i],
                    user: usersById[buyers[i].userId],
                    onTap: () => onTapBuyer(buyers[i]),
                  ),
                ],
              ],
            ),
    );
  }
}

class _BuyerRow extends StatelessWidget {
  final int rank;
  final Color color;
  final CustomerPurchaseRank buyer;
  final UserModel? user;
  final VoidCallback onTap;

  const _BuyerRow({
    required this.rank,
    required this.color,
    required this.buyer,
    required this.onTap,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final productD = user?.productDiscountPercent ?? 0;
    final deliveryD = user?.deliveryDiscountPercent ?? 0;
    final chips = <String>[
      if (productD > 0) 'جل ${productD.toStringAsFixed(0)}%',
      if (deliveryD > 0) 'گەیاندن ${deliveryD.toStringAsFixed(0)}%',
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor:
                    rank == 1 ? color : color.withValues(alpha: 0.14),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: rank == 1 ? Colors.white : color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${buyer.orderCount} داواکاری · ${buyer.itemCount} بەرهەم',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        chips.join(' · '),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.highlight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.price(buyer.totalSpent),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: color,
                    ),
                  ),
                  Icon(
                    Icons.percent_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderList extends StatelessWidget {
  final Color color;
  final String emptyText;
  final List<(String title, String meta, String value)> rows;

  const _LeaderList({
    required this.color,
    required this.emptyText,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(radius: 18),
      child: rows.isEmpty
          ? Text(
              emptyText,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: AppColors.border.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor:
                            i == 0 ? color : color.withValues(alpha: 0.14),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: i == 0 ? Colors.white : color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rows[i].$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              rows[i].$2,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11.5,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        rows[i].$3,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
