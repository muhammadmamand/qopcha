import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/hero_tags.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/product_card.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/promo_banner.dart';
import '../../widgets/special_discount_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(currentUserProvider);
    final productsAsync = ref.watch(filteredProductsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final allProductsAsync = ref.watch(productsProvider);
    final notifBadge = ref.watch(totalNotificationBadgeProvider);

    final categoryOptions = <String>['هەموو', ...AppConstants.categories.where((c) => c != 'هەموو')];
    final productCats = allProductsAsync.valueOrNull
            ?.where((p) => p.isClothing)
            .map((p) => p.category)
            .where((c) => c.isNotEmpty && !categoryOptions.contains(c))
            .toSet()
            .toList() ??
        [];
    categoryOptions.addAll(productCats);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productsProvider);
          ref.invalidate(filteredProductsProvider);
          ref.invalidate(featuredProductsProvider);
        },
        color: AppColors.secondary,
        backgroundColor: AppColors.card,
        strokeWidth: 2.5,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            if (user?.isPending == true)
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                    child: _PendingBrowseBanner(),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    user?.isPending == true ? 8 : 8,
                    20,
                    0,
                  ),
                  child: _Header(
                    name: user?.name ?? s.guest,
                    guestLabel: s.guest,
                    avatarUrl: user?.avatarUrl,
                    notificationCount: notifBadge,
                    showLanguageSwitcher: user == null,
                    onProfileTap: () => context.go('/profile'),
                    onNotificationsTap: () => context.push('/notifications'),
                  ),
                ),
              ),
            ),
            if (user?.hasUnreadApprovalNotice == true)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: _ApprovalNoticeBanner(),
                ),
              ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(8, 20, 8, 8),
                child: PromoBanner(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: _FabricMarketCard(
                  onTap: () => context.push('/fabrics'),
                ),
              ),
            ),
            if (user != null && user.hasSpecialDiscount)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  child: SpecialDiscountBanner(
                    productPercent: user.productDiscountPercent,
                    deliveryPercent: user.deliveryDiscountPercent,
                    onShopNow: () => context.go('/discounts'),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: CategoryChips(
                  selected: selectedCategory,
                  categories: categoryOptions,
                  onSelected: (cat) {
                    ref.read(selectedCategoryProvider.notifier).state = cat;
                  },
                ),
              ),
            ),
            productsAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: ProductGridShimmer(count: 6)),
              error: (e, _) => SliverFillRemaining(
                child: ErrorView(
                  message: s.productsLoadError,
                  onRetry: () => ref.invalidate(filteredProductsProvider),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyView(
                      message: s.noProductsFound,
                      icon: Icons.shopping_bag_outlined,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.54,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = products[index];
                      final tag = productHeroTag(product.id, 'grid', index);
                      return ProductCard(
                        product: product,
                        index: index,
                        heroTag: tag,
                        showShopName: false,
                        showDiscountBadge: false,
                        onTap: () =>
                            context.push('/product/${product.id}', extra: tag),
                      );
                    }, childCount: products.length),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Kept as an alternate header concept for future use.
// ignore: unused_element
class _HomeTopBar extends ConsumerWidget {
  final String name;
  final String? avatarUrl;
  final String? location;
  final VoidCallback onProfileTap;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationsTap;

  const _HomeTopBar({
    required this.name,
    required this.avatarUrl,
    required this.location,
    required this.onProfileTap,
    required this.onSearchTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final firstName = name.trim().split(' ').first;
    final locationLabel = location?.trim().isNotEmpty == true
        ? location!.trim()
        : s.pickLocation;

    return Container(
          padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -65,
                right: -55,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -45,
                child: Container(
                  width: 135,
                  height: 135,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondaryLight.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Icon(
                          Icons.checkroom_rounded,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppConstants.appName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              s.welcome(firstName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _HeaderCircleButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: onNotificationsTap,
                      ),
                      const SizedBox(width: 9),
                      GestureDetector(
                        onTap: onProfileTap,
                        child: ProfileAvatar(
                          name: name,
                          avatarValue: avatarUrl,
                          size: 44,
                          showBorder: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.white.withValues(alpha: 0.78),
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: onSearchTap,
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDF3FF),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.search_rounded,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                s.searchClothesHint,
                                style: const TextStyle(
                                  color: Color(0xFF7C7C8A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: AppAnimations.slow, curve: AppAnimations.smooth)
        .slideY(begin: -0.08, curve: AppAnimations.smooth);
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.13),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String guestLabel;
  final String? avatarUrl;
  final int notificationCount;
  final bool showLanguageSwitcher;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;

  const _Header({
    required this.name,
    required this.guestLabel,
    required this.avatarUrl,
    required this.notificationCount,
    this.showLanguageSwitcher = false,
    required this.onProfileTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    // Kurdish/Arabic RTL: profile + names on the start (right),
    // notification bell on the end (left).
    return Row(
      children: [
        GestureDetector(
          onTap: onProfileTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              ProfileAvatar(
                name: name,
                avatarValue: avatarUrl,
                size: 44,
                showBorder: true,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brand,
                      letterSpacing: -0.4,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name.trim().isEmpty
                        ? guestLabel
                        : name.trim().split(' ').first,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        if (showLanguageSwitcher) ...[
          const LanguageSwitcherButton(),
          const SizedBox(width: 8),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onNotificationsTap,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    notificationCount > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    size: 24,
                    color: notificationCount > 0
                        ? AppColors.highlight
                        : AppColors.brand,
                  ),
                  if (notificationCount > 0)
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      top: 8,
                      end: 9,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.highlight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.brandWhite,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.smooth)
        .slideY(begin: -0.06, curve: AppAnimations.smooth);
  }
}

class _PendingBrowseBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.highlight.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.highlight.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.highlight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.pendingBrowseBanner,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalNoticeBanner extends ConsumerWidget {
  const _ApprovalNoticeBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.approvalBanner,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                ref.read(authProvider.notifier).markApprovalNoticeSeen(),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _FabricMarketCard extends ConsumerWidget {
  final VoidCallback onTap;

  const _FabricMarketCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Material(
      color: AppColors.brand,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.texture_rounded,
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
                      s.fabricsSection,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.fabricsSubtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
