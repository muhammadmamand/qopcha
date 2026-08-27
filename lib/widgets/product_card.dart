import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_animations.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/utils/shop_navigation.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import 'animated_press.dart';
import 'product_image.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final bool showShopName;
  final int index;
  final bool isFeatured;
  final String? heroTag;

  /// Lists the product-level and personal discounts separately, marking which
  /// one is actually applied. Used on the discounts page.
  final bool showDiscountBreakdown;
  final bool showDiscountBadge;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showShopName = true,
    this.index = 0,
    this.isFeatured = false,
    this.heroTag,
    this.showDiscountBreakdown = false,
    this.showDiscountBadge = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).contains(product.id);
    final user = ref.watch(currentUserProvider);
    final customerId = user?.id;
    final personalDiscount = user?.productDiscountPercent ?? 0;
    final discountPercent = product.discountPercentFor(
      customerId,
      personalDiscountPercent: personalDiscount,
    );
    final productOnlyPercent = product.productDiscountPercentFor(customerId);
    final soldOut = !product.inStock;

    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withValues(alpha: AppColors.isDark ? 0.6 : 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark ? 0.22 : 0.05,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: AppColors.surfaceVariant,
                  child: _buildImage(),
                ),
                if (soldOut)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.38),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'تەواوبوو',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _FavoriteButton(
                    isFavorite: isFavorite,
                    onTap: () =>
                        ref.read(favoritesProvider.notifier).toggle(product.id),
                  ),
                ),
                if (showDiscountBadge &&
                    product.hasDiscountFor(
                      customerId,
                      personalDiscountPercent: personalDiscount,
                    ))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _Badge(
                      label: product.isAmountDiscount &&
                              product.productDiscountPercentFor(customerId) >=
                                  personalDiscount
                          ? product.discountBadgeLabel
                          : '${discountPercent.round()}٪-',
                      color: AppColors.highlight,
                    ),
                  )
                else if (product.isFabric)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _Badge(
                      label: 'قوماش',
                      color: AppColors.brand,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              showShopName ? 10 : 8,
              12,
              showShopName ? 12 : 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showShopName) ...[
                  const SizedBox(height: 4),
                  if (product.shopOwnerId.trim().isNotEmpty)
                    GestureDetector(
                      onTap: () => openShopStorefront(
                        context,
                        shopOwnerId: product.shopOwnerId,
                        shopName: product.shopName,
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 12,
                            color: AppColors.brand,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              product.shopName.trim().isEmpty
                                  ? 'سەردانی دووکان'
                                  : product.shopName,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                color: AppColors.brand,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      product.shopName.trim().isEmpty
                          ? product.category
                          : product.shopName,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
                const SizedBox(height: 8),
                _CardPrice(
                  product: product,
                  customerId: customerId,
                  personalDiscountPercent: personalDiscount,
                ),
                if (showDiscountBreakdown &&
                    (productOnlyPercent > 0 || personalDiscount > 0)) ...[
                  const SizedBox(height: 8),
                  _DiscountBreakdown(
                    productPercent: productOnlyPercent,
                    personalPercent: personalDiscount,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final wrapped = heroTag != null
        ? Hero(
            tag: heroTag!,
            child: Material(color: Colors.transparent, child: card),
          )
        : card;

    return AnimatedPress(onTap: onTap, child: wrapped)
        .animate()
        .fadeIn(
          duration: AppAnimations.normal,
          delay: (index * 70).ms,
          curve: AppAnimations.smooth,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppAnimations.slow,
          delay: (index * 70).ms,
          curve: AppAnimations.smooth,
        );
  }

  Widget _buildImage() {
    return ProductImage(
      path: product.imageUrls.first,
      fit: BoxFit.cover,
      placeholder: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(color: AppColors.shimmerBase),
      ),
    );
  }
}

/// Shows every discount that could apply to a product. The larger one wins, so
/// it is filled and tagged; the other is muted.
class _DiscountBreakdown extends StatelessWidget {
  final double productPercent;
  final double personalPercent;

  const _DiscountBreakdown({
    required this.productPercent,
    required this.personalPercent,
  });

  @override
  Widget build(BuildContext context) {
    final productWins = productPercent >= personalPercent;

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        if (productPercent > 0)
          _DiscountTag(
            icon: Icons.sell_rounded,
            label: 'بەرهەم ${productPercent.round()}٪',
            color: AppColors.highlight,
            applied: productWins,
          ),
        if (personalPercent > 0)
          _DiscountTag(
            icon: Icons.workspace_premium_rounded,
            label: 'کەسی ${personalPercent.round()}٪',
            color: AppColors.brand,
            applied: !productWins,
          ),
      ],
    );
  }
}

class _DiscountTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool applied;

  const _DiscountTag({
    required this.icon,
    required this.label,
    required this.color,
    required this.applied,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: applied
            ? color.withValues(alpha: 0.16)
            : AppColors.surfaceVariant.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: applied
              ? color.withValues(alpha: 0.5)
              : AppColors.border.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: applied ? color : AppColors.textTertiary,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: applied ? color : AppColors.textTertiary,
            ),
          ),
          if (applied) ...[
            const SizedBox(width: 3),
            Icon(Icons.check_rounded, size: 10, color: color),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}

class _CardPrice extends StatelessWidget {
  final ProductModel product;
  final String? customerId;
  final double personalDiscountPercent;

  const _CardPrice({
    required this.product,
    this.customerId,
    this.personalDiscountPercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.hasDiscountFor(
      customerId,
      personalDiscountPercent: personalDiscountPercent,
    );
    final sale = product.salePriceFor(
      customerId,
      personalDiscountPercent: personalDiscountPercent,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            Formatters.price(sale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
        ),
        if (product.isFabric) ...[
          const SizedBox(width: 4),
          Text(
            '/ مەتر',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (hasDiscount) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              Formatters.price(product.price),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.textTertiary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.textTertiary,
                height: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(isFavorite),
            size: 17,
            color: isFavorite ? AppColors.highlight : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
