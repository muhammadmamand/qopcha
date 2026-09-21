import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/hero_tags.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/maps_launcher_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_image.dart';

final shopOwnerByIdProvider =
    FutureProvider.family<UserModel?, String>((ref, shopOwnerId) async {
  return ref.watch(authServiceProvider).getUserById(shopOwnerId);
});

class ShopStorefrontScreen extends ConsumerWidget {
  final String shopOwnerId;
  final String? fallbackShopName;

  const ShopStorefrontScreen({
    super.key,
    required this.shopOwnerId,
    this.fallbackShopName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerAsync = ref.watch(shopOwnerByIdProvider(shopOwnerId));
    final productsAsync = ref.watch(shopProductsProvider(shopOwnerId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldFill,
      body: productsAsync.when(
        loading: () => const LoadingView(message: 'بارکردنی دووکان...'),
        error: (e, _) => ErrorView(
          message: 'هەڵە لە بارکردنی دووکان',
          onRetry: () {
            ref.invalidate(shopProductsProvider(shopOwnerId));
            ref.invalidate(shopOwnerByIdProvider(shopOwnerId));
          },
        ),
        data: (products) {
          final owner = ownerAsync.valueOrNull;
          final shopName = owner?.shopName?.trim().isNotEmpty == true
              ? owner!.shopName!
              : (fallbackShopName?.trim().isNotEmpty == true
                  ? fallbackShopName!
                  : (products.isNotEmpty
                      ? products.first.shopName
                      : 'دووکان'));
          final description = owner?.shopDescription?.trim();
          final address =
              owner?.shopAddress?.trim() ?? owner?.location?.trim();
          final ownerName = owner?.name.trim();
          final avatarUrl = owner?.avatarUrl?.trim();
          final logoUrl = owner?.shopLogoUrl?.trim();
          final coverUrl = owner?.shopCoverUrl?.trim();
          final tier =
              owner?.isShopOwner == true ? owner!.effectiveShopTier : null;
          final phone = owner?.phone.trim();
          final hasPhone = phone != null && phone.isNotEmpty;
          final hasAddress = address != null && address.isNotEmpty;
          final productCovers = products
              .expand((p) => p.imageUrls)
              .where((u) => u.trim().isNotEmpty)
              .take(4)
              .toList();
          final coverUrls = (coverUrl != null && coverUrl.isNotEmpty)
              ? <String>[coverUrl]
              : productCovers;
          final displayLogo =
              (logoUrl != null && logoUrl.isNotEmpty) ? logoUrl : avatarUrl;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Full-bleed shop hero — brand first.
              SliverToBoxAdapter(
                child: _ShopHero(
                  shopName: shopName,
                  ownerName: (ownerName != null && ownerName.isNotEmpty)
                      ? ownerName
                      : null,
                  description: description,
                  address: address,
                  avatarUrl: displayLogo,
                  tier: tier,
                  coverUrls: coverUrls,
                  productCount: products.length,
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  onCall: hasPhone
                      ? () async {
                          HapticFeedback.selectionClick();
                          final uri = Uri(scheme: 'tel', path: phone);
                          await launchUrl(uri);
                        }
                      : null,
                  onMaps: hasAddress
                      ? () {
                          HapticFeedback.selectionClick();
                          const MapsLauncherService().openDirections(
                            address: address,
                          );
                        }
                      : null,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'کۆلێکشن',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              products.isEmpty
                                  ? 'هێشتا هیچ بەرهەمێک نییە'
                                  : '${products.length} بەرهەم لەم دووکانە',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (products.isNotEmpty)
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brand.withValues(alpha: 0.28),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            '${products.length}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.onBrand,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 420.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOutCubic),
              ),
              if (products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(
                    message: 'ئەم دووکانە هێشتا بەرهەمی نییە',
                    icon: Icons.storefront_outlined,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 48),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        final heroTag = productHeroTag(
                          product.id,
                          'store-$shopOwnerId',
                          index,
                        );
                        return ProductCard(
                          product: product,
                          index: index,
                          showShopName: false,
                          showDiscountBadge: false,
                          heroTag: heroTag,
                          onTap: () => context.push(
                            '/product/${product.id}',
                            extra: heroTag,
                          ),
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ShopHero extends StatelessWidget {
  final String shopName;
  final String? ownerName;
  final String? description;
  final String? address;
  final String? avatarUrl;
  final ShopTier? tier;
  final List<String> coverUrls;
  final int productCount;
  final VoidCallback onBack;
  final VoidCallback? onCall;
  final VoidCallback? onMaps;

  const _ShopHero({
    required this.shopName,
    required this.ownerName,
    required this.description,
    required this.address,
    required this.avatarUrl,
    required this.tier,
    required this.coverUrls,
    required this.productCount,
    required this.onBack,
    required this.onCall,
    required this.onMaps,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final hasDesc = description != null && description!.isNotEmpty;
    final hasAddress = address != null && address!.isNotEmpty;
    final hasActions = onCall != null || onMaps != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 340 + top * 0.2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: _HeroCover(coverUrls: coverUrls)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(1.08, 1.08),
                      end: const Offset(1, 1),
                      duration: 1100.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),
              // Atmospheric gradient — keeps brand readable on any photo.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        AppColors.gradientStart.withValues(alpha: 0.35),
                        AppColors.gradientStart.withValues(alpha: 0.92),
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: top + 10,
                right: 16,
                left: 16,
                child: Row(
                  children: [
                    _GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: onBack,
                    ),
                    const Spacer(),
                    if (tier != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 14,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tier!.labelKu,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Brand-first identity block.
              Positioned(
                left: 20,
                right: 20,
                bottom: 28,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                              letterSpacing: -0.6,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 100.ms, duration: 520.ms)
                              .slideY(
                                begin: 0.2,
                                delay: 100.ms,
                                duration: 580.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          if (ownerName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              ownerName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _HeroMetaChip(
                                icon: Icons.inventory_2_outlined,
                                label: '$productCount بەرهەم',
                              ),
                              if (hasAddress) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: _HeroMetaChip(
                                    icon: Icons.place_outlined,
                                    label: address!,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _ShopAvatar(shopName: shopName, avatarUrl: avatarUrl)
                        .animate()
                        .fadeIn(delay: 160.ms, duration: 480.ms)
                        .scale(
                          begin: const Offset(0.82, 0.82),
                          end: const Offset(1, 1),
                          delay: 160.ms,
                          duration: 560.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Soft sheet under hero.
        Transform.translate(
          offset: const Offset(0, -18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
            decoration: BoxDecoration(
              color: AppColors.scaffoldFill,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasDesc)
                  Text(
                    description!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.5,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 240.ms, duration: 450.ms),
                if (hasActions) ...[
                  SizedBox(height: hasDesc ? 18 : 4),
                  Row(
                    children: [
                      if (onCall != null)
                        Expanded(
                          child: _ProfileAction(
                            label: 'پەیوەندی',
                            icon: Icons.phone_rounded,
                            filled: true,
                            onTap: onCall!,
                          ),
                        ),
                      if (onCall != null && onMaps != null)
                        const SizedBox(width: 10),
                      if (onMaps != null)
                        Expanded(
                          child: _ProfileAction(
                            label: 'نەخشە',
                            icon: Icons.map_outlined,
                            filled: false,
                            onTap: onMaps!,
                          ),
                        ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 280.ms, duration: 450.ms)
                      .slideY(
                        begin: 0.08,
                        delay: 280.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCover extends StatelessWidget {
  final List<String> coverUrls;

  const _HeroCover({required this.coverUrls});

  @override
  Widget build(BuildContext context) {
    if (coverUrls.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: const CustomPaint(painter: _SoftPatternPainter()),
      );
    }

    // Prefer one dominant full-bleed image for a cleaner modern look.
    if (coverUrls.length == 1) {
      return ProductImage(path: coverUrls.first, fit: BoxFit.cover);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ProductImage(path: coverUrls.first, fit: BoxFit.cover),
        if (coverUrls.length > 1)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FractionallySizedBox(
              widthFactor: 0.38,
              child: Opacity(
                opacity: 0.92,
                child: ProductImage(path: coverUrls[1], fit: BoxFit.cover),
              ),
            ),
          ),
      ],
    );
  }
}

class _SoftPatternPainter extends CustomPainter {
  const _SoftPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const step = 28.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShopAvatar extends StatelessWidget {
  final String shopName;
  final String? avatarUrl;

  const _ShopAvatar({required this.shopName, required this.avatarUrl});

  String get _letter {
    final t = shopName.trim();
    if (t.isEmpty) return 'د';
    return String.fromCharCodes(t.runes.take(1));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.5),
        child: ColoredBox(
          color: AppColors.brand,
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => _LetterMark(letter: _letter),
                )
              : _LetterMark(letter: _letter),
        ),
      ),
    );
  }
}

class _LetterMark extends StatelessWidget {
  final String letter;

  const _LetterMark({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ProfileAction({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.brand : AppColors.card,
      elevation: filled ? 0 : 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled
                ? null
                : Border.all(color: AppColors.border.withValues(alpha: 0.95)),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled ? Colors.white : AppColors.brand,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: filled ? Colors.white : AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
