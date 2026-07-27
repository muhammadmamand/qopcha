import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/product_image.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final String? heroTag;

  const ProductDetailScreen({super.key, required this.productId, this.heroTag});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;
  String? _selectedSize;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final favorites = ref.watch(favoritesProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAF8),
        body: productAsync.when(
          loading: () => const LoadingView(message: 'بارکردن...'),
          error: (e, _) => ErrorView(
            message: 'هەڵە لە بارکردنی بەرهەم',
            onRetry: () =>
                ref.invalidate(productDetailProvider(widget.productId)),
          ),
          data: (product) {
            if (product == null) {
              return const ErrorView(message: 'بەرهەم نەدۆزرایەوە');
            }

            final availableSizes = product.availableSizes;
            if (_selectedSize == null && availableSizes.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _selectedSize = availableSizes.first);
                }
              });
            }

            final isFavorite = favorites.contains(product.id);
            final topPad = MediaQuery.of(context).padding.top;
            final heroH = MediaQuery.of(context).size.height * 0.56;

            return Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: heroH,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildImageHeader(product),
                            Positioned(
                              top: topPad + 8,
                              left: 16,
                              right: 16,
                              child: Row(
                                children: [
                                  _FrostButton(
                                    icon: Icons.arrow_back_ios_new_rounded,
                                    onTap: () => context.pop(),
                                  ),
                                  const Spacer(),
                                  _FrostButton(
                                    icon: isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    iconColor: isFavorite
                                        ? const Color(0xFFE11D48)
                                        : const Color(0xFF1A1A22),
                                    onTap: () => ref
                                        .read(favoritesProvider.notifier)
                                        .toggle(product.id),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: const Offset(0, -52),
                        child: CustomPaint(
                          painter: _CurvedSheetShadowPainter(),
                          child: ClipPath(
                            clipper: const _CurvedTopClipper(depth: 34),
                            child: Container(
                              width: double.infinity,
                              color: const Color(0xFFFAFAF8),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      28,
                                      24,
                                      160,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Container(
                                            width: 42,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD8D4CE),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        _TopMetaRow(product: product)
                                            .animate()
                                            .fadeIn(duration: 450.ms)
                                            .slideY(
                                              begin: 0.12,
                                              curve: Curves.easeOutCubic,
                                            ),
                                        const SizedBox(height: 18),
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0E0E14),
                                        letterSpacing: -0.8,
                                        height: 1.2,
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(delay: 60.ms, duration: 480.ms)
                                        .slideY(begin: 0.08),
                                    if (product.brand.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        product.brand,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textTertiary,
                                          letterSpacing: 0.6,
                                        ),
                                      ).animate().fadeIn(delay: 90.ms),
                                    ],
                                    const SizedBox(height: 22),
                                    _LuxuryShopCard(
                                      shopName: product.shopName,
                                      onTap: () => context.push(
                                        Uri(
                                          path:
                                              '/store/${product.shopOwnerId}',
                                          queryParameters: {
                                            'name': product.shopName,
                                          },
                                        ).toString(),
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(delay: 120.ms)
                                        .slideY(begin: 0.08)
                                        .scale(
                                          begin: const Offset(0.97, 0.97),
                                          curve: Curves.easeOutCubic,
                                        ),
                                    if (product.description
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 30),
                                      const _SectionHeader(title: 'وەسف'),
                                      const SizedBox(height: 12),
                                      Text(
                                        product.description,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          color: AppColors.textSecondary,
                                          height: 1.85,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ).animate().fadeIn(delay: 160.ms),
                                    ],
                                    if (product.colors.isNotEmpty) ...[
                                      const SizedBox(height: 30),
                                      const _SectionHeader(title: 'ڕەنگ'),
                                      const SizedBox(height: 14),
                                      _ColorRow(colors: product.colors)
                                          .animate()
                                          .fadeIn(delay: 180.ms),
                                    ],
                                    const SizedBox(height: 30),
                                    const _SectionHeader(
                                      title: 'تایبەتمەندییەکان',
                                    ),
                                    const SizedBox(height: 14),
                                    _SpecsPanel(product: product)
                                        .animate()
                                        .fadeIn(delay: 200.ms)
                                        .slideY(begin: 0.05),
                                    const SizedBox(height: 30),
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: _SectionHeader(
                                            title: 'قیاس هەڵبژێرە',
                                          ),
                                        ),
                                        if (_selectedSize != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _selectedSize!,
                                              style: const TextStyle(
                                                fontFamily:
                                                    AppTheme.fontFamily,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.secondary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    _SizeSelector(
                                      product: product,
                                      selectedSize: _selectedSize,
                                      onSelected: (size) => setState(
                                        () => _selectedSize = size,
                                      ),
                                    ).animate().fadeIn(delay: 240.ms),
                                    if (product.imageUrls.length > 1) ...[
                                      const SizedBox(height: 30),
                                      const _SectionHeader(title: 'وێنەکان'),
                                      const SizedBox(height: 14),
                                      _ThumbStrip(
                                        images: product.imageUrls,
                                        current: _currentImageIndex,
                                        onTap: (i) {
                                          _pageController.animateToPage(
                                            i,
                                            duration: AppAnimations.normal,
                                            curve: AppAnimations.smooth,
                                          );
                                          setState(
                                            () => _currentImageIndex = i,
                                          );
                                        },
                                      ).animate().fadeIn(delay: 260.ms),
                                    ],
                                    const SizedBox(height: 22),
                                    _StockNote(product: product)
                                        .animate()
                                        .fadeIn(delay: 280.ms),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: productAsync.maybeWhen(
          data: (product) {
            if (product == null) return null;
            return _PremiumBottomBar(
              product: product,
              selectedSize: _selectedSize,
              onAdd: () async {
                if (_selectedSize == null) return;
                await ref
                    .read(cartProvider.notifier)
                    .addFromProduct(product, _selectedSize!);
                if (!context.mounted) return;
                context.go('/cart');
              },
            );
          },
          orElse: () => null,
        ),
      ),
    );
  }

  Widget _buildImageHeader(ProductModel product) {
    final images = product.imageUrls;
    final header = Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: const Color(0xFF16161C),
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (_, index) => ProductImage(
              path: images[index],
              fit: BoxFit.cover,
              placeholder: Container(color: const Color(0xFF22222A)),
            ),
          ),
        ),
        // Top vignette for glass buttons
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 140,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          Positioned(
            bottom: 58,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = _currentImageIndex == i;
                return AnimatedContainer(
                  duration: AppAnimations.fast,
                  curve: AppAnimations.smooth,
                  width: active ? 32 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),
          Positioned(
            bottom: 54,
            left: 22,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1} / ${images.length}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    if (widget.heroTag == null) return header;
    return Hero(tag: widget.heroTag!, child: Material(child: header));
  }
}

class _FrostButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _FrostButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withValues(alpha: 0.82),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? const Color(0xFF1A1A22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopMetaRow extends StatelessWidget {
  final ProductModel product;

  const _TopMetaRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _SoftChip(
          label: product.category,
          background: const Color(0xFFF0EEEA),
          foreground: const Color(0xFF2A2A32),
        ),
        if (product.isFeatured)
          const _SoftChip(
            label: 'تایبەت',
            background: Color(0xFFF4EBDD),
            foreground: Color(0xFF9A7340),
            icon: Icons.auto_awesome_rounded,
          ),
        _StockPill(product: product),
      ],
    );
  }
}

class _SoftChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const _SoftChip({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  final ProductModel product;

  const _StockPill({required this.product});

  @override
  Widget build(BuildContext context) {
    final color = !product.inStock
        ? AppColors.error
        : product.totalStock <= 5
            ? AppColors.warning
            : AppColors.success;
    final label = !product.inStock
        ? 'نەماوە'
        : product.totalStock <= 5
            ? 'کەم ماوە'
            : 'بەردەستە';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: AppColors.accentGradient,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0E0E14),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _LuxuryShopCard extends StatelessWidget {
  final String shopName;
  final VoidCallback onTap;

  const _LuxuryShopCard({required this.shopName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary.withValues(alpha: 0.22),
                AppColors.secondary.withValues(alpha: 0.06),
                const Color(0xFF1E3A8A).withValues(alpha: 0.12),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ئەم بەرهەمە لەلایەن',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0E0E14),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'بینینی هەموو بەرهەمەکانی دووکان',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.secondary,
                    size: 22,
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

class _ColorRow extends StatelessWidget {
  final List<String> colors;

  const _ColorRow({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < colors.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E4DF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                colors[i],
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0E0E14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecsPanel extends StatelessWidget {
  final ProductModel product;

  const _SpecsPanel({required this.product});

  @override
  Widget build(BuildContext context) {
    final specs = [
      (Icons.branding_watermark_outlined, 'براند', product.brand),
      (Icons.palette_outlined, 'ڕەنگ', product.color),
      (Icons.texture_rounded, 'ماددە', product.material),
      (Icons.inventory_2_outlined, 'کۆگا', '${product.totalStock} دانە'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEBE6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < specs.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary.withValues(alpha: 0.12),
                          AppColors.secondary.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      specs[i].$1,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    specs[i].$2,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      specs[i].$3.isEmpty ? '—' : specs[i].$3,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0E0E14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < specs.length - 1)
              Divider(
                height: 1,
                indent: 68,
                endIndent: 16,
                color: const Color(0xFFF0EDE8),
              ),
          ],
        ],
      ),
    );
  }
}

class _SizeSelector extends StatelessWidget {
  final ProductModel product;
  final String? selectedSize;
  final ValueChanged<String> onSelected;

  const _SizeSelector({
    required this.product,
    required this.selectedSize,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: product.sizeStocks.map((sizeStock) {
        final available = sizeStock.quantity > 0;
        final selected = selectedSize == sizeStock.size;

        return GestureDetector(
          onTap: available ? () => onSelected(sizeStock.size) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minWidth: 62),
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.accentGradient : null,
              color: selected
                  ? null
                  : available
                      ? Colors.white
                      : const Color(0xFFF3F1ED),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : available
                        ? const Color(0xFFE5E1DB)
                        : const Color(0xFFEDEAE6),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sizeStock.size,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: selected
                        ? Colors.white
                        : available
                            ? const Color(0xFF0E0E14)
                            : AppColors.textTertiary,
                  ),
                ),
                Text(
                  available ? '${sizeStock.quantity} دانە' : 'نەماوە',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ThumbStrip extends StatelessWidget {
  final List<String> images;
  final int current;
  final ValueChanged<int> onTap;

  const _ThumbStrip({
    required this.images,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final active = current == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              width: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active
                      ? AppColors.secondary
                      : const Color(0xFFE8E4DF),
                  width: active ? 2.2 : 1,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ProductImage(
                  path: images[i],
                  fit: BoxFit.cover,
                  placeholder: Container(color: const Color(0xFFF0EEEA)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StockNote extends StatelessWidget {
  final ProductModel product;

  const _StockNote({required this.product});

  @override
  Widget build(BuildContext context) {
    final total = product.totalStock;
    final isLow = total > 0 && total <= 5;
    final color = !product.inStock
        ? AppColors.error
        : isLow
            ? AppColors.warning
            : AppColors.success;
    final text = !product.inStock
        ? 'ئەم بەرهەمە بەردەست نییە'
        : isLow
            ? 'تەنها $total دانە ماوە — بەزوویی داوا بکە'
            : '$total دانە لە کۆگادا بەردەستە';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(
            !product.inStock
                ? Icons.cancel_rounded
                : isLow
                    ? Icons.local_fire_department_rounded
                    : Icons.verified_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBottomBar extends StatelessWidget {
  final ProductModel product;
  final String? selectedSize;
  final VoidCallback onAdd;

  const _PremiumBottomBar({
    required this.product,
    required this.selectedSize,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final canAdd = product.inStock && selectedSize != null;
    final priceText = Formatters.price(product.price);
    final parts = priceText.split(' ');
    final amount = parts.isNotEmpty ? parts.first : priceText;
    final currency = parts.length > 1 ? parts.sublist(1).join(' ') : 'IQD';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 36,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نرخ',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                        letterSpacing: -0.6,
                        height: 1.05,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      currency,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AnimatedOpacity(
                  duration: AppAnimations.fast,
                  opacity: canAdd ? 1 : 0.55,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: canAdd ? AppColors.accentGradient : null,
                      color: canAdd ? null : const Color(0xFFE8E4DF),
                      boxShadow: canAdd
                          ? [
                              BoxShadow(
                                color: AppColors.secondary
                                    .withValues(alpha: 0.42),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: canAdd ? onAdd : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              product.inStock
                                  ? Icons.shopping_bag_rounded
                                  : Icons.block_rounded,
                              size: 18,
                              color: canAdd
                                  ? Colors.white
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  !product.inStock
                                      ? 'بەردەست نییە'
                                      : selectedSize == null
                                          ? 'قیاس هەڵبژێرە'
                                          : 'زیادکردن بۆ سەبەتە',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: canAdd
                                        ? Colors.white
                                        : AppColors.textTertiary,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.14);
  }
}

/// Soft concave curve across the top of the product sheet.
class _CurvedTopClipper extends CustomClipper<Path> {
  final double depth;

  const _CurvedTopClipper({this.depth = 34});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, depth);
    path.quadraticBezierTo(
      size.width * 0.5,
      0,
      size.width,
      depth,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CurvedTopClipper oldClipper) =>
      oldClipper.depth != depth;
}

class _CurvedSheetShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 34)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width, 34)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.28),
      18,
      true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
