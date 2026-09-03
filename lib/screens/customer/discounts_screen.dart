import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/hero_tags.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../../widgets/product_card.dart';

/// Customer tab: products with an active discount for this user.
class DiscountsScreen extends ConsumerWidget {
  const DiscountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(currentUserProvider);
    final customerId = user?.id;
    final personalDiscount = user?.productDiscountPercent ?? 0;
    final deliveryDiscount = user?.deliveryDiscountPercent ?? 0;
    final productsAsync = ref.watch(productsProvider);

    // Product providers are one-shot futures. Refresh them as soon as a new
    // discount notification arrives so the newly discounted item appears here
    // without requiring an app restart.
    ref.listen(notificationsProvider, (previous, next) {
      final oldIds = (previous?.valueOrNull ?? const [])
          .map((notification) => notification.id)
          .toSet();
      final hasNewDiscount = (next.valueOrNull ?? const []).any(
        (notification) =>
            notification.isDiscountAssigned &&
            !oldIds.contains(notification.id),
      );
      if (hasNewDiscount) ref.invalidate(productsProvider);
    });

    // Only the product's own offer decides whether it belongs in the grid; the
    // personal percentage applies to everything and is listed as its own type.
    double percentOf(ProductModel p) =>
        p.productDiscountPercentFor(customerId);

    // Computed up front so the header can show counts while the body renders
    // its own loading/error states.
    final discounted =
        (productsAsync.valueOrNull ?? const <ProductModel>[])
            .where((p) => percentOf(p) > 0)
            .toList()
          ..sort((a, b) => percentOf(b).compareTo(percentOf(a)));

    final topPercent =
        discounted.isEmpty ? 0.0 : percentOf(discounted.first);
    final hasAnyDiscount = discounted.isNotEmpty ||
        personalDiscount > 0 ||
        deliveryDiscount > 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldFill,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _AmbientGlow(color: AppColors.highlight, size: 220),
          ),
          Positioned(
            top: 120,
            right: -90,
            child: _AmbientGlow(color: AppColors.brand, size: 260),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  child: _DiscountsHeader(strings: s),
                ),
                Expanded(
                  child: productsAsync.when(
                    loading: () => const ProductGridShimmer(count: 6),
                    error: (e, _) => ErrorView(
                      message: s.discountsLoadError,
                      onRetry: () => ref.invalidate(productsProvider),
                    ),
                    data: (_) {
                      if (!hasAnyDiscount) {
                        return _DiscountsEmpty(
                          strings: s,
                          onBrowse: () => context.go('/home'),
                        );
                      }

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                              child: _ActiveDiscountsPanel(
                                strings: s,
                                productCount: discounted.length,
                                productPercent: topPercent,
                                personalPercent: personalDiscount,
                                deliveryPercent: deliveryDiscount,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
                              child: _SectionTitle(
                                title: s.discountedProducts,
                                trailing: discounted.isEmpty
                                    ? null
                                    : '${discounted.length}',
                              ),
                            ),
                          ),
                          if (discounted.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  18,
                                  0,
                                  18,
                                  kPremiumBottomNavClearance + 24,
                                ),
                                child: _NoProductOffersNote(strings: s),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                14,
                                0,
                                14,
                                kPremiumBottomNavClearance + 24,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.55,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final product = discounted[index];
                                    final tag = productHeroTag(
                                      product.id,
                                      'discounts',
                                      index,
                                    );
                                    return ProductCard(
                                      product: product,
                                      heroTag: tag,
                                      showDiscountBreakdown: true,
                                      onTap: () => context.push(
                                        '/product/${product.id}',
                                        extra: tag,
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(
                                          delay: (40 * (index % 6)).ms,
                                          duration: AppAnimations.normal,
                                          curve: AppAnimations.smooth,
                                        )
                                        .slideY(
                                          begin: 0.06,
                                          delay: (40 * (index % 6)).ms,
                                          duration: AppAnimations.normal,
                                          curve: AppAnimations.smooth,
                                        );
                                  },
                                  childCount: discounted.length,
                                ),
                              ),
                            ),
                        ],
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

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: AppColors.isDark ? 0.22 : 0.13),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscountsHeader extends StatelessWidget {
  final AppStrings strings;

  const _DiscountsHeader({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.ctaGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.highlight.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_offer_rounded,
            color: Colors.white,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.discountsPageTitle,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                strings.discountsPageSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.smooth)
        .slideY(begin: -0.06, curve: AppAnimations.smooth);
  }
}

class _ActiveDiscountsPanel extends StatelessWidget {
  final AppStrings strings;
  final int productCount;
  final double productPercent;
  final double personalPercent;
  final double deliveryPercent;

  const _ActiveDiscountsPanel({
    required this.strings,
    required this.productCount,
    required this.productPercent,
    required this.personalPercent,
    required this.deliveryPercent,
  });

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Column(
      children: [
        if (personalPercent > 0)
          _TypeCard(
            icon: Icons.workspace_premium_rounded,
            color: AppColors.brand,
            title: s.personalDiscount,
            value: '${personalPercent.round()}٪',
            subtitle: s.personalDiscountSub,
            note: s.personalDiscountNote,
          ),
        if (personalPercent > 0 &&
            (deliveryPercent > 0 || productCount > 0 || productPercent > 0))
          const SizedBox(height: 10),
        if (deliveryPercent > 0)
          _TypeCard(
            icon: Icons.local_shipping_rounded,
            color: AppColors.success,
            title: s.deliveryDiscount,
            value: '${deliveryPercent.round()}٪',
            subtitle: s.deliveryDiscountSub,
          ),
        if (deliveryPercent > 0 &&
            (productCount > 0 || productPercent > 0))
          const SizedBox(height: 10),
        if (productCount > 0 || productPercent > 0)
          _TypeCard(
            icon: Icons.sell_rounded,
            color: AppColors.highlight,
            title: s.productOffer,
            value: productPercent > 0
                ? s.upToPercent(productPercent.round())
                : '$productCount',
            subtitle: productCount > 0
                ? s.productsWithOwnOffer(productCount)
                : s.productOfferActive,
          ),
      ],
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.smooth)
        .slideY(begin: 0.04, curve: AppAnimations.smooth);
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  final String? note;

  const _TypeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: AppColors.isDark ? 0.18 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note!,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10.5,
                      height: 1.35,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.highlight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailing!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.highlight,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NoProductOffersNote extends StatelessWidget {
  final AppStrings strings;

  const _NoProductOffersNote({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: AppColors.textTertiary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              strings.noProductOffersNote,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountsEmpty extends StatelessWidget {
  final AppStrings strings;
  final VoidCallback onBrowse;

  const _DiscountsEmpty({required this.strings, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          36,
          0,
          36,
          kPremiumBottomNavClearance,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.highlight.withValues(alpha: 0.16),
                    AppColors.brand.withValues(alpha: 0.10),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.card,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: AppColors.isDark ? 0.35 : 0.06,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_offer_outlined,
                    size: 32,
                    color: AppColors.highlight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              strings.noDiscountsYet,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              strings.noDiscountsHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 26),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onBrowse,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: 0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          strings.browseProducts,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal)
        .scale(
          begin: const Offset(0.96, 0.96),
          curve: AppAnimations.smooth,
        );
  }
}
