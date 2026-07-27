import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/hero_tags.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/product_card.dart';

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
      backgroundColor: AppColors.surface,
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
          final address = owner?.shopAddress?.trim() ?? owner?.location?.trim();
          final ownerName = owner?.name;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _StoreHeader(
                  shopName: shopName,
                  ownerName: ownerName,
                  description: description,
                  address: address,
                  productCount: products.length,
                  onBack: () => context.pop(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'بەرهەمەکانی دووکان',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${products.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.68,
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

class _StoreHeader extends StatelessWidget {
  final String shopName;
  final String? ownerName;
  final String? description;
  final String? address;
  final int productCount;
  final VoidCallback onBack;

  const _StoreHeader({
    required this.shopName,
    required this.ownerName,
    required this.description,
    required this.address,
    required this.productCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'دووکان',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    shopName.isEmpty ? 'د' : shopName[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (ownerName != null && ownerName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'خاوەن: $ownerName',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                _HeaderStat(
                  icon: Icons.inventory_2_outlined,
                  label: 'بەرهەم',
                  value: '$productCount',
                ),
                if (address != null && address!.isNotEmpty) ...[
                  Container(
                    width: 1,
                    height: 34,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            address!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
