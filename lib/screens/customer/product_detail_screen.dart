import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_animations.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/shop_navigation.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_details/accordion_details.dart';
import '../../widgets/product_details/bottom_action_bar.dart';
import '../../widgets/product_details/color_selector.dart';
import '../../widgets/product_details/description_section.dart';
import '../../widgets/product_details/feature_cards.dart';
import '../../widgets/product_details/mock_product_data.dart';
import '../../widgets/product_details/pd_theme.dart';
import '../../widgets/product_details/product_detail_mapper.dart';
import '../../widgets/product_details/product_gallery.dart';
import '../../widgets/product_details/product_info.dart';
import '../../widgets/product_details/related_products.dart';
import '../../widgets/product_details/size_selector.dart';

/// Premium Product Details — loads the tapped product by [productId].
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? heroTag;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.heroTag,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late final ValueNotifier<int> _imageIndex;
  late final ValueNotifier<int> _colorIndex;
  late final ValueNotifier<String?> _selectedSize;
  late final ValueNotifier<int> _quantity;
  String? _boundProductId;

  @override
  void initState() {
    super.initState();
    _imageIndex = ValueNotifier(0);
    _colorIndex = ValueNotifier(0);
    _selectedSize = ValueNotifier(null);
    _quantity = ValueNotifier(1);
  }

  @override
  void dispose() {
    _imageIndex.dispose();
    _colorIndex.dispose();
    _selectedSize.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _bindDefaults(MockProduct view, {bool isFabric = false}) {
    if (_boundProductId == view.id) return;
    _boundProductId = view.id;
    _imageIndex.value = 0;
    _colorIndex.value = 0;
    _selectedSize.value = isFabric
        ? AppConstants.fabricStockUnit
        : (view.sizes.isNotEmpty ? view.sizes.first : null);
    _quantity.value = 1;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: PdTheme.body(color: PdColors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: PdColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _addToCart(
    ProductModel product,
    MockProduct view, {
    required bool buyNow,
  }) async {
    final size = product.isFabric
        ? AppConstants.fabricStockUnit
        : _selectedSize.value;
    if (size == null) {
      _toast('تکایە قەبارە هەڵبژێرە');
      return;
    }
    if (!product.inStock) {
      _toast('ئەم بەرهەمە بەردەست نییە');
      return;
    }
    HapticFeedback.mediumImpact();
    final cart = ref.read(cartProvider.notifier);
    final user = ref.read(currentUserProvider);
    for (var i = 0; i < _quantity.value; i++) {
      await cart.addFromProduct(
        product,
        size,
        customerId: user?.id,
        personalDiscountPercent: user?.productDiscountPercent ?? 0,
      );
    }
    if (!mounted) return;
    if (buyNow) {
      context.go('/cart');
    } else {
      final color = view.colors[_colorIndex.value.clamp(0, view.colors.length - 1)].name;
      _toast(
        product.isFabric
            ? 'زیادکرا ${_quantity.value} مەتر بۆ سەبەتە'
            : 'زیادکرا ${_quantity.value}× $size · $color بۆ سەبەتە',
      );
    }
  }

  void _share(MockProduct view) {
    final color = view.colors.isEmpty
        ? ''
        : view.colors[_colorIndex.value.clamp(0, view.colors.length - 1)].name;
    final size = _selectedSize.value ?? '—';
    Clipboard.setData(
      ClipboardData(
        text:
            '${view.title}\n${Formatters.price(view.price)} · $color · $size',
      ),
    );
    _toast('لینک کۆپی کرا');
  }

  void _showSizeGuide(List<String> sizes) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PdColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              24 + MediaQuery.paddingOf(ctx).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PdColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'ڕێبەری قەبارە',
                  style: PdTheme.display(size: 20, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'قەبارە بەردەستەکان بۆ ئەم بەرهەمە',
                  style: PdTheme.body(size: 13),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: sizes
                      .map(
                        (s) => Container(
                          width: 56,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: PdColors.gray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s,
                            style: PdTheme.label(
                              size: 13,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final allProducts = ref.watch(productsProvider).valueOrNull ?? const [];
    final favorites = ref.watch(favoritesProvider);
    final topPad = MediaQuery.paddingOf(context).top;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: productAsync.when(
        loading: () => Scaffold(
          backgroundColor: PdColors.canvas,
          body: Center(
            child: CircularProgressIndicator(color: PdColors.primary),
          ),
        ),
        error: (_, _) => Scaffold(
          backgroundColor: PdColors.canvas,
          appBar: AppBar(
            backgroundColor: PdColors.canvas,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Text(
              'نەتوانرا بەرهەم ببارێنرێت',
              style: PdTheme.label(size: 15),
            ),
          ),
        ),
        data: (product) {
          if (product == null) {
            return Scaffold(
              backgroundColor: PdColors.canvas,
              appBar: AppBar(
                backgroundColor: PdColors.canvas,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
              ),
              body: Center(
                child: Text(
                  'بەرهەم نەدۆزرایەوە',
                  style: PdTheme.label(size: 15),
                ),
              ),
            );
          }

          final relatedSource = allProducts
              .where(
                (p) =>
                    p.id != product.id &&
                    p.isFabric == product.isFabric &&
                    (p.category == product.category ||
                        p.shopOwnerId == product.shopOwnerId ||
                        (product.isFabric &&
                            p.fabricType == product.fabricType)),
              )
              .toList();
          final fallbackRelated = relatedSource.isNotEmpty
              ? relatedSource
              : allProducts.where((p) => p.id != product.id).toList();

          final user = ref.watch(currentUserProvider);
          final view = toDetailView(
            product: product,
            relatedProducts: fallbackRelated,
            favoriteIds: favorites,
            customerId: user?.id,
            personalDiscountPercent: user?.productDiscountPercent ?? 0,
          );
          if (_boundProductId != view.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _bindDefaults(view, isFabric: product.isFabric);
            });
          }

          final isFav = favorites.contains(product.id);

          return Scaffold(
            backgroundColor: PdColors.canvas,
            body: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: ProductGallery(
                        imageUrls: view.imageUrls,
                        discountPercent: view.discountPercent,
                        imageIndex: _imageIndex,
                        heroTag:
                            widget.heroTag ?? 'pd-hero-${widget.productId}',
                      )
                          .animate()
                          .fadeIn(duration: AppAnimations.normal)
                          .scale(
                            begin: const Offset(1.03, 1.03),
                            end: const Offset(1, 1),
                            duration: AppAnimations.slow,
                            curve: AppAnimations.smooth,
                          ),
                    ),
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: const Offset(0, -26),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
                          decoration: BoxDecoration(
                            color: PdColors.canvas,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 44,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: PdColors.border,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _Panel(
                                child: ProductInfo(product: view),
                              )
                                  .animate()
                                  .fadeIn(
                                    delay: 80.ms,
                                    duration: AppAnimations.normal,
                                  )
                                  .slideY(
                                    begin: 0.05,
                                    delay: 80.ms,
                                    curve: AppAnimations.smooth,
                                    duration: AppAnimations.slow,
                                  ),
                              const SizedBox(height: 12),
                              _Panel(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    ColorSelector(
                                      colors: view.colors,
                                      selectedIndex: _colorIndex,
                                    ),
                                    if (!product.isFabric) ...[
                                      if (view.colors.isNotEmpty)
                                        _PanelDivider(),
                                      SizeSelector(
                                        sizes: view.sizes,
                                        selectedSize: _selectedSize,
                                        onSizeGuide: () =>
                                            _showSizeGuide(view.sizes),
                                      ),
                                    ] else ...[
                                      if (view.colors.isNotEmpty)
                                        _PanelDivider(),
                                      _FabricBuyHint(
                                        meters: product.totalStock,
                                        priceLabel: Formatters.price(view.price),
                                      ),
                                    ],
                                  ],
                                ),
                              ).animate().fadeIn(
                                    delay: 120.ms,
                                    duration: AppAnimations.normal,
                                  ),
                              if (product.isFabric) ...[
                                const SizedBox(height: 12),
                                _Panel(
                                  child: _FabricSpecs(product: product),
                                ).animate().fadeIn(
                                      delay: 170.ms,
                                      duration: AppAnimations.normal,
                                    ),
                              ],
                              const SizedBox(height: 12),
                              const FeatureCards()
                                  .animate()
                                  .fadeIn(
                                    delay: 160.ms,
                                    duration: AppAnimations.normal,
                                  ),
                              const SizedBox(height: 12),
                              _Panel(
                                child: DescriptionSection(
                                  description: view.description,
                                  fabricBadge: view.fabricBadge,
                                ),
                              ).animate().fadeIn(
                                    delay: 190.ms,
                                    duration: AppAnimations.normal,
                                  ),
                              const SizedBox(height: 12),
                              _VisitShopCard(
                                shopName: product.shopName,
                                shopOwnerId: product.shopOwnerId,
                                onTap: () => openShopStorefront(
                                  context,
                                  shopOwnerId: product.shopOwnerId,
                                  shopName: product.shopName,
                                ),
                              ).animate().fadeIn(
                                    delay: 220.ms,
                                    duration: AppAnimations.normal,
                                  ),
                              const SizedBox(height: 22),
                              AccordionDetails(items: view.details)
                                  .animate()
                                  .fadeIn(
                                    delay: 250.ms,
                                    duration: AppAnimations.normal,
                                  ),
                              if (view.related.isNotEmpty) ...[
                                const SizedBox(height: 28),
                                RelatedProducts(
                                  products: view.related,
                                  onTap: (p) =>
                                      context.push('/product/${p.id}'),
                                )
                                    .animate()
                                    .fadeIn(
                                      delay: 280.ms,
                                      duration: AppAnimations.normal,
                                    )
                                    .slideY(
                                      begin: 0.05,
                                      delay: 280.ms,
                                      curve: AppAnimations.smooth,
                                      duration: AppAnimations.slow,
                                    ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: topPad + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                      const Spacer(),
                      _CircleIconButton(
                        icon: Icons.share_rounded,
                        onTap: () => _share(view),
                      ),
                      const SizedBox(width: 10),
                      _CircleIconButton(
                        icon: isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: isFav ? PdColors.accent : Colors.white,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(favoritesProvider.notifier)
                              .toggle(product.id);
                        },
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: AppAnimations.fast)
                    .slideY(begin: -0.15, curve: AppAnimations.smooth),
              ],
            ),
            bottomNavigationBar: BottomActionBar(
              quantity: _quantity,
              maxQty: product.totalStock > 0 ? product.totalStock : 1,
              onAddToCart: () => _addToCart(product, view, buyNow: false),
              onBuyNow: () => _addToCart(product, view, buyNow: true),
            ),
          );
        },
      ),
    );
  }
}

/// Rounded surface used to group each block of product details.
class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PdColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PdColors.border.withValues(alpha: 0.55)),
        boxShadow: PdTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _PanelDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: PdColors.border.withValues(alpha: 0.7),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Dark translucent chrome reads well over any product photo, in both modes.
    return Material(
      color: Colors.transparent,
      elevation: 0,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.38),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 21,
            color: iconColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}

class _VisitShopCard extends StatelessWidget {
  final String shopName;
  final String shopOwnerId;
  final VoidCallback onTap;

  const _VisitShopCard({
    required this.shopName,
    required this.shopOwnerId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (shopOwnerId.trim().isEmpty) return const SizedBox.shrink();
    final name = shopName.trim().isEmpty ? 'دووکان' : shopName.trim();

    return Material(
      color: PdColors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: PdColors.border.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PdColors.primary.withValues(alpha: 0.16),
                      PdColors.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: PdColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PdTheme.label(size: 14, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'سەردانی پرۆفایلی دووکان',
                      style: PdTheme.body(
                        size: 12,
                        color: PdColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: PdColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FabricBuyHint extends StatelessWidget {
  final int meters;
  final String priceLabel;

  const _FabricBuyHint({required this.meters, required this.priceLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('کڕین بە مەتر', style: PdTheme.label(size: 13)),
          const SizedBox(height: 6),
          Text(
            '$priceLabel بۆ هەر مەترێک · $meters مەتر بەردەستە',
            style: PdTheme.body(size: 13),
          ),
        ],
      ),
    );
  }
}

class _FabricSpecs extends StatelessWidget {
  final ProductModel product;

  const _FabricSpecs({required this.product});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (product.fabricType.isNotEmpty) ('جۆر', product.fabricType),
      if (product.fabricQuality.isNotEmpty) ('کوالێتی', product.fabricQuality),
      if (product.fabricPattern.isNotEmpty) ('نەخش', product.fabricPattern),
      if (product.material.isNotEmpty) ('پێکهاتە', product.material),
      if (product.fabricWidthCm > 0)
        ('پانی', '${product.fabricWidthCm.toStringAsFixed(0)} سم'),
      if (product.fabricWeightGsm > 0) ('کێش', '${product.fabricWeightGsm} GSM'),
      if (product.fabricOrigin.isNotEmpty) ('وڵات', product.fabricOrigin),
      ('کۆگا', '${product.totalStock} مەتر'),
      if (product.fabricCare.isNotEmpty) ('پاراستن', product.fabricCare),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('وردەکاری قوماش', style: PdTheme.label(size: 14)),
        const SizedBox(height: 12),
        for (var i = 0; i < rows.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  rows[i].$1,
                  style: PdTheme.body(size: 13, color: PdColors.textSecondary),
                ),
              ),
              Expanded(
                child: Text(rows[i].$2, style: PdTheme.body(size: 13.5)),
              ),
            ],
          ),
          if (i != rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
