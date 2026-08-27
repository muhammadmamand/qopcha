import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/hero_tags.dart';
import '../../core/utils/shop_navigation.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../../widgets/product_image.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'سڕینەوەی دڵخوازەکان',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'دڵنیایت دەتەوێت هەموو دڵخوازەکان بسڕیتەوە؟',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('نەخێر'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('بەڵێ، بسڕەوە'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(favoritesProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.highlight.withValues(alpha: 0.12),
                    AppColors.highlight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: 0.10),
                    AppColors.brand.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 18, 8),
                  child: _FavoritesHeader(
                    count: favoriteIds.length,
                    onBack: () {
                      HapticFeedback.selectionClick();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/profile');
                      }
                    },
                    onClear: favoriteIds.isEmpty
                        ? null
                        : () => _confirmClear(context, ref),
                  ),
                ),
                Expanded(
                  child: productsAsync.when(
                    loading: () => const ProductGridShimmer(count: 4),
                    error: (e, _) => ErrorView(
                      message: 'هەڵە لە بارکردنی دڵخوازەکان',
                      onRetry: () => ref.invalidate(productsProvider),
                    ),
                    data: (products) {
                      final favorites = products
                          .where((p) => favoriteIds.contains(p.id))
                          .toList();

                      if (favorites.isEmpty) {
                        return _FavoritesEmpty(
                          onBrowse: () => context.go('/home'),
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          10,
                          20,
                          kPremiumBottomNavClearance + 24,
                        ),
                        itemCount: favorites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final product = favorites[index];
                          final tag = productHeroTag(
                            product.id,
                            'favorites',
                            index,
                          );
                          return _FavoriteTile(
                            product: product,
                            heroTag: tag,
                            index: index,
                            customerId: ref.watch(currentUserProvider)?.id,
                            personalDiscountPercent: ref
                                    .watch(currentUserProvider)
                                    ?.productDiscountPercent ??
                                0,
                            onTap: () => context.push(
                              '/product/${product.id}',
                              extra: tag,
                            ),
                            onRemove: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(product.id);
                            },
                          );
                        },
                      );
                    },
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

class _FavoritesHeader extends StatelessWidget {
  final int count;
  final VoidCallback onBack;
  final VoidCallback? onClear;

  const _FavoritesHeader({
    required this.count,
    required this.onBack,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              tooltip: 'گەڕانەوە',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.highlight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: AppColors.highlight,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'دڵخوازەکان',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    count == 0
                        ? 'بەرهەمە خۆشەویستەکانت لێرە کۆدەبنەوە'
                        : '$count بەرهەم هەڵبژێردراو',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                tooltip: 'سڕینەوەی هەموو',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.08),
                  foregroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        if (count > 0) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brand.withValues(alpha: 0.10),
                  AppColors.highlight.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.brand.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'کلیک لەسەر بەرهەم بکە بۆ بینین، یان دڵ لابەر',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.smooth)
        .slideY(begin: -0.06, curve: AppAnimations.smooth);
  }
}

class _FavoriteTile extends StatelessWidget {
  final ProductModel product;
  final String heroTag;
  final int index;
  final String? customerId;
  final double personalDiscountPercent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteTile({
    required this.product,
    required this.heroTag,
    required this.index,
    required this.onTap,
    required this.onRemove,
    this.customerId,
    this.personalDiscountPercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercentFor(
      customerId,
      personalDiscountPercent: personalDiscountPercent,
    );
    final hasDiscount = discount > 0;
    final sale = product.salePriceFor(
      customerId,
      personalDiscountPercent: personalDiscountPercent,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 108,
                      height: 118,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ProductImage(
                            path: product.imageUrls.isNotEmpty
                                ? product.imageUrls.first
                                : '',
                            fit: BoxFit.cover,
                          ),
                          if (hasDiscount)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.highlight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '-${discount.toStringAsFixed(0)}%',
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
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 118,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (product.shopName.trim().isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              openShopStorefront(
                                context,
                                shopOwnerId: product.shopOwnerId,
                                shopName: product.shopName,
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.storefront_rounded,
                                  size: 14,
                                  color: AppColors.brand.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    product.shopName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_left_rounded,
                                  size: 16,
                                  color: AppColors.brand.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Formatters.price(sale),
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                  if (hasDiscount)
                                    Text(
                                      Formatters.price(product.price),
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Material(
                              color: AppColors.highlight.withValues(alpha: 0.12),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onRemove,
                                child: SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    color: AppColors.highlight,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: (40 * index).ms,
          duration: AppAnimations.normal,
          curve: AppAnimations.smooth,
        )
        .slideY(begin: 0.06, curve: AppAnimations.smooth);
  }
}

class _FavoritesEmpty extends StatelessWidget {
  final VoidCallback onBrowse;

  const _FavoritesEmpty({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          36,
          8,
          36,
          kPremiumBottomNavClearance + 24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.highlight.withValues(alpha: 0.18),
                    AppColors.brand.withValues(alpha: 0.12),
                  ],
                ),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 54,
                color: AppColors.highlight,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.96, 0.96),
                  end: const Offset(1.04, 1.04),
                  duration: 1400.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 28),
            Text(
              'هێشتا دڵخواز نییە',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'بەرهەمەکانی خۆشەویستت لێرە پاشەکەوت بکە بۆ دواتر',
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
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.ctaGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.highlight.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: onBrowse,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('گەڕان بۆ بەرهەمەکان'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.06);
  }
}
