import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/product_image.dart';

class ShopDashboardScreen extends ConsumerWidget {
  const ShopDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();

    final productsAsync = ref.watch(shopProductsProvider(user.id));
    final ordersAsync = ref.watch(shopOrdersProvider);
    final pendingCount = ref.watch(shopPendingOrdersCountProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(shopProductsProvider(user.id));
          await ref.read(shopOrdersNotifierProvider.notifier).load();
        },
        color: AppColors.secondary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHeader(
                shopName: user.shopName ?? 'دووکانەکەم',
                ownerName: user.name,
                pendingOrders: pendingCount,
                onOrdersTap: () => context.go('/shop-orders'),
              ),
            ),
            productsAsync.when(
              loading: () => const SliverFillRemaining(child: LoadingView()),
              error: (e, _) => SliverFillRemaining(
                child: ErrorView(
                  message: 'هەڵە لە بارکردن',
                  onRetry: () => ref.invalidate(shopProductsProvider(user.id)),
                ),
              ),
              data: (products) {
                final totalStock = products.fold<int>(
                  0,
                  (sum, p) => sum + p.totalStock,
                );
                final totalValue = products.fold<double>(
                  0,
                  (sum, p) => sum + (p.price * p.totalStock),
                );
                final orders = ordersAsync.valueOrNull ?? [];
                final sales = orders
                    .where((o) => o.status == OrderStatus.completed)
                    .fold<double>(0, (sum, o) {
                  final shop = user.shopName ?? '';
                  return sum +
                      (shop.isEmpty ? o.total : o.totalForShop(shop));
                });
                final lowStock = products
                    .where((p) => p.totalStock > 0 && p.totalStock <= 5)
                    .length;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section 1 — Overview
                            _SectionLabel(title: 'پوختە'),
                            const SizedBox(height: 10),
                            _OverviewCard(
                              productCount: products.length,
                              stockCount: totalStock,
                              orderCount: orders.length,
                              pendingCount: pendingCount,
                              sales: Formatters.price(sales),
                              inventoryValue: Formatters.price(totalValue),
                            ),

                            const SizedBox(height: 22),

                            // Section 2 — Quick actions
                            _SectionLabel(title: 'کردارە خێراکان'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickAction(
                                    icon: Icons.add_rounded,
                                    label: 'بەرهەمی نوێ',
                                    color: AppColors.secondary,
                                    onTap: () =>
                                        context.push('/shop/add-product'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _QuickAction(
                                    icon: Icons.receipt_long_rounded,
                                    label: 'داواکارییەکان',
                                    color: AppColors.warning,
                                    badge: pendingCount > 0
                                        ? pendingCount
                                        : null,
                                    onTap: () => context.go('/shop-orders'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _QuickAction(
                                    icon: Icons.storefront_outlined,
                                    label: 'پڕۆفایلی دووکان',
                                    color: const Color(0xFF7C3AED),
                                    onTap: () => context.go('/shop-profile'),
                                  ),
                                ),
                              ],
                            ),

                            if (lowStock > 0) ...[
                              const SizedBox(height: 14),
                              _AlertBanner(
                                message:
                                    '$lowStock بەرهەم کەمی کاڵایان هەیە (٥ یان کەمتر)',
                              ),
                            ],

                            const SizedBox(height: 22),

                            // Section 3 — Products
                            Row(
                              children: [
                                const Expanded(
                                  child: _SectionLabel(title: 'بەرهەمەکان'),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${products.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            if (products.isEmpty)
                              const _EmptyProducts()
                            else
                              Container(
                                decoration: AppDecorations.card(radius: 22),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < products.length; i++) ...[
                                      _ShopProductTile(
                                        product: products[i],
                                        index: i,
                                        onEdit: () => context.push(
                                          '/shop/edit-product/${products[i].id}',
                                        ),
                                        onDelete: () => _confirmDelete(
                                          context,
                                          ref,
                                          products[i].id,
                                          user.id,
                                        ),
                                      ),
                                      if (i < products.length - 1)
                                        Divider(
                                          height: 1,
                                          indent: 88,
                                          endIndent: 16,
                                          color: AppColors.border
                                              .withValues(alpha: 0.7),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String productId,
    String shopOwnerId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('سڕینەوەی بەرهەم'),
        content: const Text('دڵنیایت لە سڕینەوەی ئەم بەرهەمە؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('پاشگەزبوونەوە'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('سڕینەوە'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(productNotifierProvider.notifier)
          .deleteProduct(productId, shopOwnerId);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String shopName;
  final String ownerName;
  final int pendingOrders;
  final VoidCallback onOrdersTap;

  const _DashboardHeader({
    required this.shopName,
    required this.ownerName,
    required this.pendingOrders,
    required this.onOrdersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        36,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'سڵاو، $ownerName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onOrdersTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Badge(
                  isLabelVisible: pendingOrders > 0,
                  label: Text(
                    '$pendingOrders',
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _OverviewCard extends StatelessWidget {
  final int productCount;
  final int stockCount;
  final int orderCount;
  final int pendingCount;
  final String sales;
  final String inventoryValue;

  const _OverviewCard({
    required this.productCount,
    required this.stockCount,
    required this.orderCount,
    required this.pendingCount,
    required this.sales,
    required this.inventoryValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: 22),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.inventory_2_rounded,
                  label: 'بەرهەم',
                  value: '$productCount',
                  color: AppColors.secondary,
                ),
              ),
              _Divider(),
              Expanded(
                child: _Metric(
                  icon: Icons.layers_rounded,
                  label: 'کۆگا',
                  value: '$stockCount',
                  color: const Color(0xFF7C3AED),
                ),
              ),
              _Divider(),
              Expanded(
                child: _Metric(
                  icon: Icons.receipt_long_rounded,
                  label: 'داواکاری',
                  value: '$orderCount',
                  color: AppColors.warning,
                ),
              ),
              _Divider(),
              Expanded(
                child: _Metric(
                  icon: Icons.schedule_rounded,
                  label: 'چاوەڕوان',
                  value: '$pendingCount',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MoneyLine(label: 'فرۆشتن', value: sales),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border,
                ),
                Expanded(
                  child: _MoneyLine(label: 'نرخی کۆگا', value: inventoryValue),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 40.ms).slideY(begin: 0.04);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: AppColors.border.withValues(alpha: 0.8),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final String value;

  const _MoneyLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int? badge;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: AppDecorations.card(radius: 16),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String message;

  const _AlertBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: AppDecorations.card(radius: 22),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'هێشتا هیچ بەرهەمێکت نییە',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'یەکەم بەرهەمەکەت زیاد بکە',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopProductTile extends StatelessWidget {
  final ProductModel product;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShopProductTile({
    required this.product,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lowStock = product.totalStock > 0 && product.totalStock <= 5;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ProductImage(
                  path: product.imageUrls.first,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.price(product.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: lowStock
                                ? AppColors.warning.withValues(alpha: 0.12)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '${product.totalStock} دانە',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: lowStock
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            product.availableSizes.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('دەستکاری'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'سڕینەوە',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
