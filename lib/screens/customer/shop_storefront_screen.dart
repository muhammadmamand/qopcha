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
      backgroundColor: const Color(0xFFF7F9FA),
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
              .take(3)
              .toList();
          final coverUrls = (coverUrl != null && coverUrl.isNotEmpty)
              ? <String>[coverUrl]
              : productCovers;
          final displayLogo = (logoUrl != null && logoUrl.isNotEmpty)
              ? logoUrl
              : null;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _ShopHero(
                  shopName: shopName,
                  ownerName: (ownerName != null && ownerName.isNotEmpty)
                      ? ownerName
                      : null,
                  description: description,
                  address: address,
                  avatarUrl: displayLogo ?? avatarUrl,
                  tier: tier,
                  coverUrls: coverUrls,
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
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'کۆلێکشن',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${products.length}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 220.ms, duration: 450.ms)
                    .slideY(
                      begin: 0.06,
                      delay: 220.ms,
                      curve: Curves.easeOutCubic,
                    ),
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
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 48),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.66,
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
    required this.onBack,
    required this.onCall,
    required this.onMaps,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final hasDesc = description != null && description!.isNotEmpty;
    final hasActions = onCall != null || onMaps != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 300 + top * 0.15,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: _HeroCover(coverUrls: coverUrls)
                    .animate()
                    .fadeIn(duration: 550.ms)
                    .scale(
                      begin: const Offset(1.06, 1.06),
                      end: const Offset(1, 1),
                      duration: 900.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x26000000),
                        Color(0x590D3D42),
                        Color(0xEB0D3D42),
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: top + 8,
                right: 16,
                left: 16,
                child: Row(
                  children: [
                    _GlassIconButton(
                      icon: Icons.arrow_back_rounded,
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
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          tier!.labelKu,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                right: 110,
                bottom: 56,
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
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: -0.4,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 120.ms, duration: 500.ms)
                        .slideY(
                          begin: 0.18,
                          delay: 120.ms,
                          duration: 550.ms,
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
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                bottom: -42,
                right: 20,
                child: _ShopAvatar(
                  shopName: shopName,
                  avatarUrl: avatarUrl,
                )
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 450.ms)
                    .scale(
                      begin: const Offset(0.86, 0.86),
                      end: const Offset(1, 1),
                      delay: 180.ms,
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
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
                ).animate().fadeIn(delay: 260.ms, duration: 450.ms),
              if (address != null && address!.isNotEmpty) ...[
                SizedBox(height: hasDesc ? 14 : 0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: AppColors.brand.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address!,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms, duration: 450.ms),
              ],
              if (hasActions) ...[
                const SizedBox(height: 18),
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
                    .fadeIn(delay: 340.ms, duration: 450.ms)
                    .slideY(
                      begin: 0.08,
                      delay: 340.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ],
          ),
        ),
      ],
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
        child: CustomPaint(painter: _SoftPatternPainter()),
      );
    }

    if (coverUrls.length == 1) {
      return ProductImage(path: coverUrls.first, fit: BoxFit.cover);
    }

    return Row(
      children: [
        for (var i = 0; i < coverUrls.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            flex: i == 0 ? 3 : 2,
            child: ProductImage(path: coverUrls[i], fit: BoxFit.cover),
          ),
        ],
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
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
          child: Icon(icon, color: Colors.white, size: 22),
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
      color: filled ? AppColors.brand : Colors.white,
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
