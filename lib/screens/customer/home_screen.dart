import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/hero_tags.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/product_card.dart';
import '../../widgets/promo_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final productsAsync = ref.watch(filteredProductsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final allProductsAsync = ref.watch(productsProvider);

    final categoryOptions = <String>['هەموو', ...AppConstants.categories.where((c) => c != 'هەموو')];
    final productCats = allProductsAsync.valueOrNull
            ?.map((p) => p.category)
            .where((c) => c.isNotEmpty && !categoryOptions.contains(c))
            .toSet()
            .toList() ??
        [];
    categoryOptions.addAll(productCats);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
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
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _Header(
                    name: user?.name ?? 'هاوڕێ',
                    avatarUrl: user?.avatarUrl,
                    onProfileTap: () => context.go('/profile'),
                    onNotificationsTap: () =>
                        _showNotificationsSheet(context),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 20, 18, 8),
                child: PromoBanner(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
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
                  message: 'هەڵە لە بارکردنی بەرهەمەکان',
                  onRetry: () => ref.invalidate(filteredProductsProvider),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyView(
                      message: 'هیچ بەرهەمێک نەدۆزرایەوە',
                      icon: Icons.shopping_bag_outlined,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 120),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.66,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = products[index];
                      final tag = productHeroTag(product.id, 'grid', index);
                      return ProductCard(
                        product: product,
                        index: index,
                        heroTag: tag,
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
class _HomeTopBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final firstName = name.trim().split(' ').first;
    final locationLabel = location?.trim().isNotEmpty == true
        ? location!.trim()
        : 'شوێن دیاری بکە';

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
                              'بەخێربێیت، $firstName',
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
                        child: _HeaderAvatar(name: name, avatarUrl: avatarUrl),
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
                              child: const Icon(
                                Icons.search_rounded,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 11),
                            const Expanded(
                              child: Text(
                                'گەڕان بۆ جل و بەرگ...',
                                style: TextStyle(
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

class _HeaderAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _HeaderAvatar({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
        color: AppColors.surfaceVariant,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => _HeaderAvatarFallback(name: name),
              placeholder: (_, _) => _HeaderAvatarFallback(name: name),
            )
          : _HeaderAvatarFallback(name: name),
    );
  }
}

class _HeaderAvatarFallback extends StatelessWidget {
  final String name;

  const _HeaderAvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.brand,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;

  const _Header({
    required this.name,
    required this.avatarUrl,
    required this.onProfileTap,
    required this.onNotificationsTap,
  });

  static const _notificationCount = 2;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          // Left: profile + app name
          GestureDetector(
            onTap: onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _HeaderAvatar(name: name, avatarUrl: avatarUrl),
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
                      name.trim().isEmpty ? 'هاوڕێ' : name.trim().split(' ').first,
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
          // Right: notification bell
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
                      Icons.notifications_none_rounded,
                      size: 24,
                      color: AppColors.brand,
                    ),
                    if (_notificationCount > 0)
                      Positioned(
                        top: 8,
                        right: 9,
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
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.smooth)
        .slideY(begin: -0.06, curve: AppAnimations.smooth);
  }
}

void _showNotificationsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.brandWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.notifications_rounded, color: AppColors.brand),
                  const SizedBox(width: 10),
                  Text(
                    'ئاگادارییەکان',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _NotificationTile(
                icon: Icons.local_offer_rounded,
                color: AppColors.highlight,
                title: 'داشکاندنی تایبەت',
                subtitle: 'تا ٣٠٪ داشکاندن لەسەر کۆت و پێڵاو',
              ),
              const SizedBox(height: 10),
              _NotificationTile(
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                title: 'ئاگاداری',
                subtitle: 'هەندێک بەرهەم کەم ماوە لە کۆگا',
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _NotificationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
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