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
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          const _Atmosphere(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 16, 4),
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
                        final suggestions = products
                            .where((p) => !favoriteIds.contains(p.id))
                            .take(8)
                            .toList();
                        return _FavoritesEmpty(
                          suggestions: suggestions,
                          customerId: user?.id,
                          personalDiscountPercent:
                              user?.productDiscountPercent ?? 0,
                          onBrowse: () => context.go('/home'),
                          onOpenProduct: (product, index) {
                            final tag = productHeroTag(
                              product.id,
                              'fav_suggest',
                              index,
                            );
                            context.push(
                              '/product/${product.id}',
                              extra: tag,
                            );
                          },
                          onToggleFavorite: (id) {
                            HapticFeedback.lightImpact();
                            ref.read(favoritesProvider.notifier).toggle(id);
                          },
                        );
                      }

                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          18,
                          6,
                          18,
                          kPremiumBottomNavClearance + 24,
                        ),
                        itemCount: favorites.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _SavedBanner(count: favorites.length);
                          }
                          final product = favorites[index - 1];
                          final tag = productHeroTag(
                            product.id,
                            'favorites',
                            index - 1,
                          );
                          return _FavoriteTile(
                            product: product,
                            heroTag: tag,
                            index: index - 1,
                            customerId: user?.id,
                            personalDiscountPercent:
                                user?.productDiscountPercent ?? 0,
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

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.highlight.withValues(alpha: 0.16),
                    AppColors.highlight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: -110,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: 0.14),
                    AppColors.brand.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.10),
                    AppColors.gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
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
                backgroundColor: AppColors.card.withValues(alpha: 0.92),
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.highlight.withValues(alpha: 0.22),
                              AppColors.brand.withValues(alpha: 0.14),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.highlight.withValues(alpha: 0.22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.highlight.withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: AppColors.highlight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'دڵخوازەکان',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    count == 0
                        ? 'کۆلێکشنێکی تایبەت بۆ بەرهەمە خۆشەویستەکانت'
                        : '$count بەرهەم لە لیستی دڵخوازەکانت',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
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
      ],
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.smooth)
        .slideY(begin: -0.05, curve: AppAnimations.smooth);
  }
}

class _SavedBanner extends StatelessWidget {
  final int count;

  const _SavedBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.brand.withValues(alpha: 0.12),
            AppColors.highlight.withValues(alpha: 0.10),
            AppColors.gold.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لیستی تایبەتی تۆ',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'کلیک بکە بۆ بینین · دڵ لابەر بۆ سڕینەوە',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.highlight.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.highlight,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04);
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
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
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
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 112,
                      height: 124,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ProductImage(
                            path: product.imageUrls.isNotEmpty
                                ? product.imageUrls.first
                                : '',
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 48,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.35),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (hasDiscount)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.highlight,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.highlight
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
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
                          if (product.category.trim().isNotEmpty)
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  product.category,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
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
                    height: 124,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15.5,
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
                                  color: AppColors.brand.withValues(alpha: 0.9),
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
                                      fontSize: 16.5,
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
                              color: AppColors.highlight.withValues(alpha: 0.14),
                              shape: const CircleBorder(),
                              elevation: 0,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onRemove,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    color: AppColors.highlight,
                                    size: 22,
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
        .slideY(begin: 0.05, curve: AppAnimations.smooth);
  }
}

class _FavoritesEmpty extends StatelessWidget {
  final List<ProductModel> suggestions;
  final String? customerId;
  final double personalDiscountPercent;
  final VoidCallback onBrowse;
  final void Function(ProductModel product, int index) onOpenProduct;
  final void Function(String id) onToggleFavorite;

  const _FavoritesEmpty({
    required this.suggestions,
    required this.onBrowse,
    required this.onOpenProduct,
    required this.onToggleFavorite,
    this.customerId,
    this.personalDiscountPercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        kPremiumBottomNavClearance + 28,
      ),
      children: [
        const _EmptyHero(),
        const SizedBox(height: 28),
        Text(
          'هێشتا دڵخواز نییە',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.04),
        const SizedBox(height: 10),
        Text(
          'بەرهەمە خۆشەویستەکانت لێرە کۆدەکەیتەوە\nبۆ کڕین یان بەراوردکردن لە دواتردا',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ).animate().fadeIn(delay: 120.ms),
        const SizedBox(height: 26),
        const _HowItWorks(),
        const SizedBox(height: 26),
        SizedBox(
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.highlight.withValues(alpha: 0.32),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onBrowse,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shopping_bag_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'گەڕان بۆ بەرهەمەکان',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.06),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 34),
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 20,
                color: AppColors.highlight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'پێشنیارکراو بۆ تۆ',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onBrowse,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'بینینی هەموو',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 260.ms),
          const SizedBox(height: 12),
          SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = suggestions[index];
                return _SuggestCard(
                  product: product,
                  index: index,
                  customerId: customerId,
                  personalDiscountPercent: personalDiscountPercent,
                  onTap: () => onOpenProduct(product, index),
                  onFavorite: () => onToggleFavorite(product.id),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.highlight.withValues(alpha: 0.20),
                  AppColors.brand.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.94, 0.94),
                end: const Offset(1.05, 1.05),
                duration: 2200.ms,
                curve: Curves.easeInOut,
              ),
          Positioned(
            top: 28,
            right: 48,
            child: Icon(
              Icons.favorite_rounded,
              size: 22,
              color: AppColors.highlight.withValues(alpha: 0.45),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -8, duration: 1600.ms)
                .fade(begin: 0.5, end: 1),
          ),
          Positioned(
            bottom: 36,
            left: 42,
            child: Icon(
              Icons.favorite_rounded,
              size: 16,
              color: AppColors.brand.withValues(alpha: 0.40),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: 7, duration: 1800.ms)
                .fade(begin: 0.4, end: 0.9),
          ),
          Positioned(
            top: 48,
            left: 56,
            child: Icon(
              Icons.favorite_border_rounded,
              size: 18,
              color: AppColors.gold.withValues(alpha: 0.55),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -6, duration: 2000.ms),
          ),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.card,
                  AppColors.highlight.withValues(alpha: 0.12),
                  AppColors.brand.withValues(alpha: 0.10),
                ],
              ),
              border: Border.all(
                color: AppColors.highlight.withValues(alpha: 0.28),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.highlight.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 52,
              color: AppColors.highlight,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.96, 0.96),
                end: const Offset(1.05, 1.05),
                duration: 1400.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms).scale(
          begin: const Offset(0.92, 0.92),
          curve: Curves.easeOutCubic,
        );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.search_rounded, 'بگەڕێ', 'بەرهەمێکی خۆش بدۆزەوە'),
      (Icons.favorite_border_rounded, 'دڵ بکە', 'ئایکۆنی دڵ لێبدە'),
      (Icons.bookmark_added_rounded, 'پاشەکەوت', 'لێرە دەبینیتەوە'),
    ];

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.65),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: i == 1
                          ? AppColors.highlight.withValues(alpha: 0.14)
                          : AppColors.brand.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      steps[i].$1,
                      size: 20,
                      color: i == 1 ? AppColors.highlight : AppColors.brand,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    steps[i].$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i].$3,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: (140 + i * 60).ms)
                .slideY(begin: 0.08),
          ),
        ],
      ],
    );
  }
}

class _SuggestCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  final String? customerId;
  final double personalDiscountPercent;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _SuggestCard({
    required this.product,
    required this.index,
    required this.onTap,
    required this.onFavorite,
    this.customerId,
    this.personalDiscountPercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final sale = product.salePriceFor(
      customerId,
      personalDiscountPercent: personalDiscountPercent,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 156,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: ProductImage(
                        path: product.imageUrls.isNotEmpty
                            ? product.imageUrls.first
                            : '',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onFavorite,
                          child: const SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 18,
                              color: Color(0xFFF15C22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.price(sale),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (280 + index * 50).ms)
        .slideX(begin: 0.06);
  }
}
