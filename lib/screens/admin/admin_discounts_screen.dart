import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/profile_avatars.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/product_image.dart';
import '../../widgets/profile_avatar.dart';
import 'admin_shell.dart';

class AdminDiscountsScreen extends ConsumerWidget {
  const AdminDiscountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);
    final usersAsync = ref.watch(allManagedUsersProvider);
    final width = MediaQuery.sizeOf(context).width;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeader(
            title: 'داشکاندن',
            subtitle: 'ئۆفەر بۆ دووکان · کاڵا · کڕیار',
            showNotifications: true,
            action: IconButton(
              onPressed: () => _openEditor(context, ref),
              tooltip: 'داشکاندنی نوێ',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.brand.withValues(alpha: 0.10),
              ),
              icon: Icon(Icons.add_rounded, color: AppColors.brand),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
              error: (e, _) => Center(child: Text('$e')),
              data: (products) {
                final users = usersAsync.valueOrNull ?? const <UserModel>[];
                final discounted = products
                    .where((p) => p.hasConfiguredDiscount)
                    .toList()
                  ..sort((a, b) => a.shopName.compareTo(b.shopName));

                if (discounted.isEmpty) {
                  return _DiscountsEmpty(
                    onCreate: () => _openEditor(context, ref),
                  );
                }

                final avg = discounted.fold<double>(
                      0,
                      (s, p) => s + p.discountPercent,
                    ) /
                    discounted.length;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                        child: _DiscountStatsRow(
                          count: discounted.length,
                          avgPercent: avg,
                          onCreate: () => _openEditor(context, ref),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      sliver: SliverList.separated(
                        itemCount: discounted.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final p = discounted[index];
                          UserModel? shop;
                          for (final u in users) {
                            if (u.isShopOwner && u.id == p.shopOwnerId) {
                              shop = u;
                              break;
                            }
                          }
                          return _MenuDiscountCard(
                            product: p,
                            shop: shop,
                            wide: width >= 900,
                            onEdit: () =>
                                _openEditor(context, ref, product: p),
                            onClear: () async {
                              await ref
                                  .read(adminServiceProvider)
                                  .clearProductDiscount(p.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'داشکاندنی ${p.name} لابرا',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    ProductModel? product,
  }) async {
    final products = ref.read(adminProductsProvider).valueOrNull;
    final users = ref.read(allManagedUsersProvider).valueOrNull;
    if (products == null || products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'هیچ کاڵایەک نییە بۆ داشکاندن',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
      );
      return;
    }

    final customers = (users ?? const <UserModel>[])
        .where((u) => u.isCustomer && u.isApproved)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final shopOwners = (users ?? const <UserModel>[])
            .where((u) => u.isShopOwner)
            .toList();
        return _DiscountEditorSheet(
          products: products,
          customers: customers,
          shopOwners: shopOwners,
          initial: product,
          onSave: (productId, percent, forAll, customerIds) async {
            await ref.read(adminServiceProvider).setProductDiscount(
                  productId,
                  percent,
                  forAllCustomers: forAll,
                  customerIds: customerIds,
                );
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'داشکاندن پاشەکەوت کرا ($percent%)',
                  style: const TextStyle(fontFamily: AppTheme.fontFamily),
                ),
                backgroundColor: AppColors.brand,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }
}

class _DiscountsEmpty extends StatelessWidget {
  final VoidCallback onCreate;

  const _DiscountsEmpty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.07),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brand.withValues(alpha: 0.14),
                      AppColors.highlight.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  size: 34,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'هیچ داشکاندنێک دانەنراوە',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'دووکان و کاڵا و کڕیار هەڵبژێرە بۆ دانانی ئۆفەرێکی جوان',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'داشکاندنی نوێ',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscountStatsRow extends StatelessWidget {
  final int count;
  final double avgPercent;
  final VoidCallback onCreate;

  const _DiscountStatsRow({
    required this.count,
    required this.avgPercent,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatPill(
            icon: Icons.local_offer_outlined,
            label: 'ئۆفەری چالاک',
            value: '$count',
            color: AppColors.brand,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            icon: Icons.trending_down_rounded,
            label: 'ناوەندی داشکان',
            value: '${avgPercent.toStringAsFixed(0)}%',
            color: AppColors.highlight,
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onCreate,
            borderRadius: BorderRadius.circular(18),
            child: const SizedBox(
              width: 52,
              height: 72,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuDiscountCard extends StatelessWidget {
  final ProductModel product;
  final UserModel? shop;
  final bool wide;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  const _MenuDiscountCard({
    required this.product,
    required this.onEdit,
    required this.onClear,
    required this.wide,
    this.shop,
  });

  String get _audienceLabel {
    if (product.discountForAllCustomers) return 'هەموو کڕیارەکان';
    final n = product.discountCustomerIds.length;
    return n == 0 ? 'کڕیار دیارینەکراو' : '$n کڕیار';
  }

  String get _shopTitle {
    final fromUser = shop?.shopName?.trim();
    if (fromUser != null && fromUser.isNotEmpty) return fromUser;
    if (product.shopName.trim().isNotEmpty) return product.shopName;
    return 'دووکان';
  }

  @override
  Widget build(BuildContext context) {
    final image =
        product.imageUrls.isNotEmpty ? product.imageUrls.first : '';
    final sale = product.configuredSalePrice;
    final thumb = wide ? 132.0 : 108.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8EEEE)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF146B72).withValues(alpha: 0.045),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(wide ? 14 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Soft padded product frame — no overlays on the photo
                Container(
                  width: thumb,
                  height: thumb,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ProductImage(
                      path: image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: wide ? 18 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w900,
                                fontSize: wide ? 16.5 : 15,
                                height: 1.25,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.isShopSetDiscount)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.highlight.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'دووکان',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.highlight,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.ctaGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              product.discountBadgeLabel,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            size: 14,
                            color: AppColors.brand.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _shopTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '·',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _audienceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Formatters.price(product.price),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.textTertiary,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              Text(
                                Formatters.price(sale),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: wide ? 20 : 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                  color: AppColors.highlight,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _CardAction(
                            icon: Icons.edit_rounded,
                            color: AppColors.brand,
                            tooltip: 'دەستکاری',
                            onTap: onEdit,
                          ),
                          const SizedBox(width: 8),
                          _CardAction(
                            icon: Icons.delete_outline_rounded,
                            color: AppColors.error,
                            tooltip: 'لابردن',
                            onTap: onClear,
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
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _CardAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class _DiscountEditorSheet extends StatefulWidget {
  final List<ProductModel> products;
  final List<UserModel> customers;
  final List<UserModel> shopOwners;
  final ProductModel? initial;
  final Future<void> Function(
    String productId,
    double percent,
    bool forAll,
    List<String> customerIds,
  ) onSave;

  const _DiscountEditorSheet({
    required this.products,
    required this.customers,
    required this.shopOwners,
    required this.onSave,
    this.initial,
  });

  @override
  State<_DiscountEditorSheet> createState() => _DiscountEditorSheetState();
}

class _DiscountEditorSheetState extends State<_DiscountEditorSheet> {
  late String? _shopKey;
  late String? _productId;
  late double _percent;
  late bool _forAll;
  late Set<String> _selectedCustomerIds;
  String _customerQuery = '';
  bool _saving = false;

  List<_ShopOption> get _shops {
    final map = <String, _ShopOption>{};
    final ownersById = {
      for (final u in widget.shopOwners) u.id: u,
    };

    for (final p in widget.products) {
      final key = p.shopOwnerId.isNotEmpty
          ? p.shopOwnerId
          : 'name:${p.shopName}';
      final owner = ownersById[p.shopOwnerId];
      final existing = map[key];
      if (existing == null) {
        final cover = p.imageUrls.isNotEmpty ? p.imageUrls.first : '';
        final name = (owner?.shopName?.trim().isNotEmpty == true)
            ? owner!.shopName!.trim()
            : (p.shopName.trim().isEmpty ? 'دووکانی نەناسراو' : p.shopName);
        map[key] = _ShopOption(
          key: key,
          ownerId: p.shopOwnerId,
          name: name,
          imageUrl: cover,
          avatarValue: owner?.avatarUrl,
          productCount: 1,
        );
      } else {
        map[key] = existing.copyWith(
          productCount: existing.productCount + 1,
          imageUrl: existing.imageUrl.isNotEmpty
              ? existing.imageUrl
              : (p.imageUrls.isNotEmpty ? p.imageUrls.first : ''),
        );
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<ProductModel> get _shopProducts {
    if (_shopKey == null) return const [];
    return widget.products.where((p) {
      final key =
          p.shopOwnerId.isNotEmpty ? p.shopOwnerId : 'name:${p.shopName}';
      return key == _shopKey;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  ProductModel? get _selectedProduct {
    if (_productId == null) return null;
    for (final p in widget.products) {
      if (p.id == _productId) return p;
    }
    return null;
  }

  List<UserModel> get _filteredCustomers {
    final q = _customerQuery.trim().toLowerCase();
    if (q.isEmpty) return widget.customers;
    return widget.customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.phone.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _shopKey = initial.shopOwnerId.isNotEmpty
          ? initial.shopOwnerId
          : 'name:${initial.shopName}';
      _productId = initial.id;
      _percent = initial.discountPercent.clamp(0, 70);
      _forAll = initial.discountForAllCustomers;
      _selectedCustomerIds = {...initial.discountCustomerIds};
    } else {
      final shops = _shops;
      _shopKey = shops.isNotEmpty ? shops.first.key : null;
      final products = _shopProducts;
      _productId = products.isNotEmpty ? products.first.id : null;
      _percent = 10;
      _forAll = true;
      _selectedCustomerIds = {};
    }
  }

  Future<void> _submit() async {
    final product = _selectedProduct;
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تکایە کاڵا هەڵبژێرە',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
      );
      return;
    }
    if (!_forAll && _selectedCustomerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تکایە لانیکەم یەک کڕیار هەڵبژێرە',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
      );
      return;
    }
    if (_percent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ڕێژەی داشکاندن دەبێت لە سفر زیاتر بێت',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(
        product.id,
        _percent,
        _forAll,
        _selectedCustomerIds.toList(),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'نەتوانرا پاشەکەوت بکرێت',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final product = _selectedProduct;
    final sale = product == null
        ? 0.0
        : product.price * (1 - _percent.clamp(0, 100) / 100);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.88,
          child: Column(
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.local_offer_rounded,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initial == null
                              ? 'داشکاندنی نوێ'
                              : 'دەستکاری داشکاندن',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'دووکان → کاڵا → کڕیار',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _SectionLabel(number: '١', title: 'دووکان هەڵبژێرە'),
                    const SizedBox(height: 8),
                    if (_shops.isEmpty)
                      Text(
                        'هیچ دووکانێک نەدۆزرایەوە',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      )
                    else
                      SizedBox(
                        height: 128,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _shops.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final shop = _shops[i];
                            final selected = shop.key == _shopKey;
                            return _ShopPickCard(
                              shop: shop,
                              selected: selected,
                              onTap: () {
                                setState(() {
                                  _shopKey = shop.key;
                                  final products = _shopProducts;
                                  _productId = products.isNotEmpty
                                      ? products.first.id
                                      : null;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 18),
                    _SectionLabel(number: '٢', title: 'کاڵا هەڵبژێرە'),
                    const SizedBox(height: 8),
                    if (_shopProducts.isEmpty)
                      Text(
                        'ئەم دووکانە هیچ کاڵایەکی نییە',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      )
                    else
                      SizedBox(
                        height: 198,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _shopProducts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final p = _shopProducts[i];
                            final selected = p.id == _productId;
                            final previewSale =
                                p.price * (1 - _percent.clamp(0, 100) / 100);
                            final image = p.imageUrls.isNotEmpty
                                ? p.imageUrls.first
                                : '';
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _productId = p.id),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 132,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.brand
                                          : AppColors.border,
                                      width: selected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (selected
                                                ? AppColors.brand
                                                : AppColors.border)
                                            .withValues(
                                          alpha: selected ? 0.14 : 0.35,
                                        ),
                                        blurRadius: selected ? 14 : 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(14),
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ProductImage(
                                                path: image,
                                                fit: BoxFit.cover,
                                              ),
                                              if (selected)
                                                Positioned(
                                                  top: 6,
                                                  left: 6,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(3),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: AppColors.brand,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check_rounded,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          8,
                                          6,
                                          8,
                                          8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: AppTheme.fontFamily,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11.5,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              Formatters.price(p.price),
                                              style: TextStyle(
                                                fontFamily: AppTheme.fontFamily,
                                                fontSize: 10,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                            Text(
                                              Formatters.price(previewSale),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: AppTheme.fontFamily,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12.5,
                                                color: AppColors.highlight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (product != null) ...[
                      const SizedBox(height: 12),
                      _SelectedProductPreview(
                        product: product,
                        percent: _percent,
                        salePrice: sale,
                      ),
                    ],
                    const SizedBox(height: 18),
                    _SectionLabel(number: '٣', title: 'ڕێژەی داشکاندن'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.highlight.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'چەند لەسەد داشکاندن؟',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.ctaGradient,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.highlight
                                          .withValues(alpha: 0.28),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${_percent.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 11,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 18,
                              ),
                              activeTrackColor: AppColors.brand,
                              inactiveTrackColor:
                                  AppColors.brand.withValues(alpha: 0.12),
                              thumbColor: AppColors.brand,
                              overlayColor:
                                  AppColors.brand.withValues(alpha: 0.12),
                            ),
                            child: Slider(
                              value: _percent,
                              min: 0,
                              max: 70,
                              divisions: 14,
                              label: '${_percent.toStringAsFixed(0)}%',
                              onChanged: (v) => setState(() => _percent = v),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final q in const [10.0, 20.0, 30.0, 50.0])
                                ChoiceChip(
                                  label: Text(
                                    '${q.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: _percent == q
                                          ? Colors.white
                                          : AppColors.brand,
                                    ),
                                  ),
                                  selected: _percent == q,
                                  selectedColor: AppColors.brand,
                                  backgroundColor:
                                      AppColors.brand.withValues(alpha: 0.08),
                                  side: BorderSide(
                                    color: _percent == q
                                        ? AppColors.brand
                                        : AppColors.border,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _percent = q),
                                  showCheckmark: false,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel(number: '٤', title: 'کڕیارەکان'),
                    const SizedBox(height: 8),
                    _AudienceOption(
                      selected: _forAll,
                      title: 'هەموو کڕیارەکان',
                      subtitle: 'داشکاندن بۆ هەموو هەژمارە پەسەندکراوەکان',
                      icon: Icons.groups_outlined,
                      onTap: () => setState(() => _forAll = true),
                    ),
                    const SizedBox(height: 8),
                    _AudienceOption(
                      selected: !_forAll,
                      title: 'کڕیاری دیاریکراو',
                      subtitle: 'تەنها ئەو کڕیارانەی هەڵیدەبژێریت',
                      icon: Icons.person_search_outlined,
                      onTap: () => setState(() => _forAll = false),
                    ),
                    if (!_forAll) ...[
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (v) => setState(() => _customerQuery = v),
                        decoration: const InputDecoration(
                          hintText: 'گەڕان بە ناو / ئیمەیڵ / مۆبایل',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCustomerIds = {
                                  ...widget.customers.map((c) => c.id),
                                };
                              });
                            },
                            child: const Text('هەموویان'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _selectedCustomerIds = {});
                            },
                            child: const Text('هیچیان'),
                          ),
                          const Spacer(),
                          Text(
                            '${_selectedCustomerIds.length} هەڵبژێردراو',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.9),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: widget.customers.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'هیچ کڕیارێکی پەسەندکراو نییە',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: _filteredCustomers.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: AppColors.border.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                itemBuilder: (_, i) {
                                  final c = _filteredCustomers[i];
                                  final selected =
                                      _selectedCustomerIds.contains(c.id);
                                  return CheckboxListTile(
                                    value: selected,
                                    dense: true,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    activeColor: AppColors.brand,
                                    title: Text(
                                      c.name,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    subtitle: Text(
                                      c.phone.trim().isNotEmpty
                                          ? c.phone
                                          : c.email,
                                      textDirection: TextDirection.ltr,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedCustomerIds.add(c.id);
                                        } else {
                                          _selectedCustomerIds.remove(c.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.brand.withValues(alpha: 0.45),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: _saving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_circle_rounded, size: 22),
                label: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'پاشەکەوتکردنی داشکاندن',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedProductPreview extends StatelessWidget {
  final ProductModel product;
  final double percent;
  final double salePrice;

  const _SelectedProductPreview({
    required this.product,
    required this.percent,
    required this.salePrice,
  });

  @override
  Widget build(BuildContext context) {
    final image =
        product.imageUrls.isNotEmpty ? product.imageUrls.first : '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.brand.withValues(alpha: 0.08),
            AppColors.highlight.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 76,
              height: 76,
              child: ProductImage(path: image, fit: BoxFit.cover),
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
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نرخی کۆن',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            Formatters.price(product.price),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.5,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.highlight.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'دوای ${percent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.highlight,
                            ),
                          ),
                          Text(
                            Formatters.price(salePrice),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.highlight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopOption {
  final String key;
  final String ownerId;
  final String name;
  final String imageUrl;
  final String? avatarValue;
  final int productCount;

  const _ShopOption({
    required this.key,
    required this.ownerId,
    required this.name,
    required this.imageUrl,
    required this.productCount,
    this.avatarValue,
  });

  _ShopOption copyWith({
    String? imageUrl,
    String? avatarValue,
    int? productCount,
  }) {
    return _ShopOption(
      key: key,
      ownerId: ownerId,
      name: name,
      imageUrl: imageUrl ?? this.imageUrl,
      avatarValue: avatarValue ?? this.avatarValue,
      productCount: productCount ?? this.productCount,
    );
  }
}

class _ShopPickCard extends StatelessWidget {
  final _ShopOption shop;
  final bool selected;
  final VoidCallback onTap;

  const _ShopPickCard({
    required this.shop,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 132,
          height: 128,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brand.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? AppColors.brand : AppColors.border)
                    .withValues(alpha: selected ? 0.14 : 0.35),
                blurRadius: selected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: 112,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (ProfileAvatars.isIconValue(shop.avatarValue))
                        ProfileAvatar(
                          name: shop.name,
                          avatarValue: shop.avatarValue,
                          size: 42,
                          showBorder: true,
                        )
                      else
                        ClipOval(
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: shop.imageUrl.isEmpty
                                ? ColoredBox(
                                    color: AppColors.brand
                                        .withValues(alpha: 0.12),
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      color: AppColors.brand,
                                      size: 22,
                                    ),
                                  )
                                : ProductImage(
                                    path: shop.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      if (selected)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.brand,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      height: 1.1,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${shop.productCount} کاڵا',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
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

class _SectionLabel extends StatelessWidget {
  final String number;
  final String title;

  const _SectionLabel({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: AppColors.brand,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _AudienceOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AudienceOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brand.withValues(alpha: 0.08)
                : AppColors.surfaceVariant.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.brand.withValues(alpha: 0.45)
                  : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.brand : AppColors.textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.brand : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
