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

class ShopDashboardScreen extends ConsumerStatefulWidget {
  const ShopDashboardScreen({super.key});

  @override
  ConsumerState<ShopDashboardScreen> createState() =>
      _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends ConsumerState<ShopDashboardScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _listKind = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> _filter(List<ProductModel> products) {
    var list = products;
    if (_listKind == 'fabric') {
      list = list.where((p) => p.isFabric).toList();
    } else if (_listKind == 'clothing') {
      list = list.where((p) => p.isClothing).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((p) {
      final hay = [
        p.name,
        p.category,
        p.brand,
        p.material,
        p.fabricType,
        p.colors.join(' '),
        p.description,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Future<void> _openAddChooser() async {
    final kind = await showModalBottomSheet<String>(
      context: context,
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
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'چی زیاد دەکەیت؟',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(Icons.checkroom_rounded, color: AppColors.brand),
                  title: const Text('جل و بەرگ'),
                  subtitle: const Text('پۆشاک، پێڵاو، جانتا...'),
                  onTap: () => Navigator.pop(ctx, 'clothing'),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(Icons.texture_rounded, color: AppColors.brand),
                  title: const Text('قوماش'),
                  subtitle: const Text('فرۆشتن بە مەتر — جۆر، کوالێتی، ڕەنگ'),
                  onTap: () => Navigator.pop(ctx, 'fabric'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || kind == null) return;
    if (kind == 'fabric') {
      context.push('/shop/add-product?kind=fabric');
    } else {
      context.push('/shop/add-product');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                final filtered = _filter(products);
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
                final clothingCount =
                    products.where((p) => p.isClothing).length;
                final fabricCount = products.where((p) => p.isFabric).length;
                final lowStock = products
                    .where((p) => p.totalStock > 0 && p.totalStock <= 5)
                    .length;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(title: 'پوختە'),
                          const SizedBox(height: 10),
                          _SalesBanner(value: Formatters.price(sales)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _StatTile(
                                  icon: Icons.inventory_2_rounded,
                                  label: 'بەرهەم',
                                  value: '${products.length}',
                                  hint:
                                      '$clothingCount جل · $fabricCount قوماش',
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatTile(
                                  icon: Icons.layers_rounded,
                                  label: 'کۆگا',
                                  value: '$totalStock',
                                  hint: Formatters.price(totalValue),
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _PendingTile(
                            pendingCount: pendingCount,
                            orderCount: orders.length,
                            onTap: () => context.go('/shop-orders'),
                          ),

                          if (lowStock > 0) ...[
                            const SizedBox(height: 10),
                            _AlertBanner(
                              message:
                                  '$lowStock بەرهەم کەمی کاڵایان هەیە (٥ یان کەمتر)',
                            ),
                          ],

                          const SizedBox(height: 22),
                          const _SectionLabel(title: 'کردارە خێراکان'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _QuickAction(
                                  icon: Icons.add_rounded,
                                  label: 'بەرهەمی نوێ',
                                  color: AppColors.secondary,
                                  onTap: _openAddChooser,
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

                          const SizedBox(height: 22),
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
                                  '${filtered.length}'
                                  '${filtered.length != products.length ? ' / ${products.length}' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _KindFilter(
                            value: _listKind,
                            onChanged: (value) =>
                                setState(() => _listKind = value),
                          ),
                          const SizedBox(height: 10),
                          _ProductSearchField(
                            controller: _searchCtrl,
                            query: _query,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            onClear: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                          const SizedBox(height: 14),
                          if (products.isEmpty)
                            _EmptyProducts(onAdd: _openAddChooser)
                          else if (filtered.isEmpty)
                            _NoSearchResults(query: _query)
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.64,
                              ),
                              itemBuilder: (context, i) {
                                final p = filtered[i];
                                return _ShopProductCard(
                                  product: p,
                                  index: i,
                                  onEdit: () => context.push(
                                    '/shop/edit-product/${p.id}',
                                  ),
                                  onDiscount: () => _openDiscountSheet(p),
                                  onDelete: () => _confirmDelete(
                                    context,
                                    ref,
                                    p.id,
                                    user.id,
                                  ),
                                );
                              },
                            ),
                        ],
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

  Future<void> _openDiscountSheet(ProductModel product) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    var type = product.discountType == DiscountKind.amount
        ? DiscountKind.amount
        : DiscountKind.percent;
    var percent = product.discountPercent.clamp(0, 70).toDouble();
    final amountCtrl = TextEditingController(
      text: product.discountAmount > 0
          ? Formatters.grouped(product.discountAmount.round())
          : '',
    );
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final price = product.price;
            final isAmount = type == DiscountKind.amount;
            final amount = Formatters.parseAmount(amountCtrl.text.trim()) ?? 0;
            final sale = isAmount
                ? (price - amount).clamp(0, price).toDouble()
                : price * (1 - percent / 100);
            final active = isAmount ? amount > 0 : percent > 0;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
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
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'داشکاندن',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _SheetTypeTab(
                          label: 'ڕێژە ٪',
                          selected: !isAmount,
                          onTap: () => setSheetState(
                            () => type = DiscountKind.percent,
                          ),
                        ),
                        _SheetTypeTab(
                          label: 'بڕ IQD',
                          selected: isAmount,
                          onTap: () => setSheetState(
                            () => type = DiscountKind.amount,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isAmount)
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      textDirection: TextDirection.ltr,
                      autofocus: true,
                      inputFormatters: [ThousandsSeparatorFormatter()],
                      onChanged: (_) => setSheetState(() {}),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: AppColors.highlight,
                      ),
                      decoration: InputDecoration(
                        labelText: 'چەند دینار دەکەیتەوە لە نرخ',
                        hintText: 'نموونە: 5,000',
                        prefixIcon: Icon(
                          Icons.payments_outlined,
                          color: AppColors.highlight,
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Text(
                          '${percent.round()}٪',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.highlight,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          Formatters.price(sale),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: percent,
                      min: 0,
                      max: 70,
                      divisions: 14,
                      activeColor: AppColors.highlight,
                      onChanged: (value) =>
                          setSheetState(() => percent = value),
                    ),
                  ],
                  if (active) ...[
                    const SizedBox(height: 8),
                    Text(
                      'نرخی دوای داشکاندن: ${Formatters.price(sale)}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                      ),
                    ),
                    Text(
                      'نرخی پێشوو: ${Formatters.price(price)}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'ئەم داشکاندنە بۆ هەموو کڕیارەکان دەردەکەوێت',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('پاشگەزبوونەوە'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(active ? 'پاشەکەوت' : 'لابردنی داشکاندن'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    final amount = Formatters.parseAmount(amountCtrl.text.trim()) ?? 0;
    amountCtrl.dispose();
    if (saved != true || !mounted) return;
    final ok = await ref.read(productNotifierProvider.notifier).setProductDiscount(
          product: product,
          shopOwnerId: user.id,
          type: type,
          percent: percent,
          amount: amount,
        );
    if (!mounted) return;
    final cleared = type == DiscountKind.amount ? amount <= 0 : percent <= 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (cleared
                  ? 'داشکاندن لابرا'
                  : type == DiscountKind.amount
                      ? 'داشکاندنی ${Formatters.price(amount)} دانرا و کڕیارەکان ئاگادار کران'
                      : 'داشکاندنی ${percent.round()}٪ دانرا و کڕیارەکان ئاگادار کران')
              : 'نەتوانرا داشکاندن پاشەکەوت بکرێت',
          style: const TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
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
        20,
      ),
      decoration: BoxDecoration(
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

class _SalesBanner extends StatelessWidget {
  final String value;

  const _SalesBanner({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: AppDecorations.gradientCard(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'فرۆشی تەواوکراو',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 40.ms).slideY(begin: 0.04);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: AppDecorations.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
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
    );
  }
}

class _PendingTile extends StatelessWidget {
  final int pendingCount;
  final int orderCount;
  final VoidCallback onTap;

  const _PendingTile({
    required this.pendingCount,
    required this.orderCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: AppDecorations.card(radius: 18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'داواکارییە چاوەڕوانەکان',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$orderCount داواکاریی گشتی',
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
                '$pendingCount',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTypeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetTypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.highlight : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _KindFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _KindFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('all', 'هەموو'),
      ('clothing', 'جلوبەرگ'),
      ('fabric', 'قوماش'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == item.$1 ? AppColors.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: value == item.$1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: value == item.$1
                          ? AppColors.brand
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ProductSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'گەڕان بۆ بەرهەم یان قوماش…',
        hintStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: AppColors.textTertiary,
          fontSize: 13,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.brand),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded, color: AppColors.textTertiary),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.7),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.brand, width: 1.4),
        ),
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
          Icon(
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
  final VoidCallback onAdd;

  const _EmptyProducts({required this.onAdd});

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
              fontFamily: AppTheme.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'یەکەم بەرهەمەکەت زیاد بکە',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('زیادکردنی بەرهەم'),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  final String query;

  const _NoSearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: AppDecorations.card(radius: 22),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'هیچ جل و بەرگێک نەدۆزرایەوە',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'بۆ «$query»',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopProductCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDiscount;
  final VoidCallback onDelete;

  const _ShopProductCard({
    required this.product,
    required this.index,
    required this.onEdit,
    required this.onDiscount,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lowStock = product.totalStock > 0 && product.totalStock <= 5;
    final image = product.imageUrls.isNotEmpty ? product.imageUrls.first : '';

    return Material(
      color: AppColors.card,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(17),
                        ),
                        child: image.isEmpty
                            ? Container(
                                color: AppColors.surfaceVariant,
                                child: Icon(
                                  Icons.checkroom_rounded,
                                  color: AppColors.textTertiary,
                                  size: 36,
                                ),
                              )
                            : ProductImage(
                                path: image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
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
                              value: 'discount',
                              child: Row(
                                children: [
                                  Icon(Icons.percent_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('داشکاندن'),
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
                            if (value == 'discount') onDiscount();
                            if (value == 'delete') onDelete();
                          },
                        ),
                      ),
                    ),
                    if (product.hasDiscount)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.highlight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            product.discountBadgeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.price(product.configuredSalePrice),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                        fontSize: 13,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(height: 2),
                      Text(
                        Formatters.price(product.price),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: lowStock
                                ? AppColors.warning.withValues(alpha: 0.12)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.totalStock} دانە',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: lowStock
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (product.category.trim().isNotEmpty)
                          Flexible(
                            child: Text(
                              product.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
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
            ],
          ),
        ),
      ),
    )
        .animate(delay: (40 * index).ms)
        .fadeIn(duration: 320.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }
}



