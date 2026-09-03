import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/shop_navigation.dart';
import '../../models/cart_item.dart';
import '../../models/address_model.dart';
import '../../providers/addresses_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/login_required_dialog.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../../widgets/product_image.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  Future<void> _checkout() async {
    final s = ref.read(stringsProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) {
      await showLoginRequiredDialog(
        context,
        message: s.loginToCheckoutBody,
        nextPath: '/cart',
      );
      return;
    }
    if (!user.canPlaceOrders) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isPending ? s.pendingCannotOrder : s.cannotOrder,
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.highlight,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Ensure addresses stream is warm; migrate legacy location if needed.
    await ref.read(addressesProvider.future).catchError((_) => <AddressModel>[]);
    var addresses = ref.read(addressesProvider).valueOrNull ?? const [];

    if (addresses.isEmpty) {
      final legacy = user.location?.trim() ?? '';
      if (legacy.isEmpty) {
        if (!mounted) return;
        final goSetLocation = await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'location-warning',
          barrierColor: Colors.black.withValues(alpha: 0.28),
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (dialogContext, animation, secondaryAnimation) {
            return const SizedBox.shrink();
          },
          transitionBuilder:
              (dialogContext, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.16, 1, 0.3, 1),
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
                child: const _IosLiquidGlassAlert(),
              ),
            );
          },
        );

        if (goSetLocation == true && mounted) {
          context.push('/settings/addresses');
        }
        return;
      }
    }

    if (!mounted) return;
    final selected = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _CheckoutAddressSheet(
        addresses: addresses.isNotEmpty
            ? addresses
            : [
                AddressModel.create(
                  label: s.primary,
                  location: user.location!.trim(),
                  latitude: user.latitude,
                  longitude: user.longitude,
                  isDefault: true,
                ),
              ],
      ),
    );
    if (selected == null || !mounted) return;

    final items = ref.read(cartProvider);
    final created = await ref
        .read(ordersProvider.notifier)
        .placeOrder(items, deliveryAddress: selected);
    if (created.isEmpty) return;

    await ref.read(cartProvider.notifier).clear();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created.length == 1
              ? s.orderSent
              : s.ordersSentMultiple(created.length),
          style: const TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        backgroundColor: AppColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
    context.go('/orders');
  }

  Future<void> _confirmClear() async {
    final s = ref.read(stringsProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scaffoldFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          s.clearCartTitle,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          s.clearCartBody,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(cartProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final count = ref.watch(cartItemCountProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldFill,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.brand.withValues(alpha: 0.10),
                      AppColors.brand.withValues(alpha: 0.02),
                      AppColors.surface.withValues(alpha: 0),
                    ],
                  ),
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
                  padding: const EdgeInsets.fromLTRB(24, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.cart,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                color: AppColors.textPrimary,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(
                                  begin: 0.08,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 4),
                            Text(
                              items.isEmpty
                                  ? s.noItems
                                  : s.cartItemsSubtitle(count),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ).animate().fadeIn(delay: 60.ms, duration: 350.ms),
                          ],
                        ),
                      ),
                      if (items.isNotEmpty)
                        TextButton.icon(
                          onPressed: _confirmClear,
                          icon: Icon(
                            Icons.delete_sweep_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          label: Text(
                            s.clearCart,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const _EmptyCart()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            20,
                            8,
                            20,
                            kPremiumBottomNavClearance + 160,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _CartTile(item: items[index])
                                .animate(delay: (40 + index * 45).ms)
                                .fadeIn(
                                  duration: AppAnimations.normal,
                                  curve: AppAnimations.smooth,
                                )
                                .slideY(
                                  begin: 0.06,
                                  curve: AppAnimations.smooth,
                                );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : _CheckoutBar(
              itemCount: count,
              total: total,
              canCheckout: user == null || user.canPlaceOrders,
              pendingAccount: user?.isPending ?? false,
              guestCheckout: user == null,
              onCheckout: _checkout,
              onContinue: () => context.go('/home'),
            ),
    );
  }
}

class _EmptyCart extends ConsumerWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 12, 40, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Lottie.asset(
                'assets/lottie/empty_cart.json',
                fit: BoxFit.contain,
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.shopping_bag_outlined,
                    size: 72,
                    color: AppColors.brand,
                  );
                },
              ),
            )
                .animate()
                .fadeIn(duration: 420.ms)
                .scale(
                  begin: const Offset(0.92, 0.92),
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 8),
            Text(
              s.cartEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 350.ms),
            const SizedBox(height: 8),
            Text(
              s.cartEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ).animate().fadeIn(delay: 120.ms, duration: 350.ms),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.storefront_rounded, size: 20),
                label: Text(
                  s.backToShop,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 180.ms, duration: 350.ms),
          ],
        ),
      ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  final CartItem item;

  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/product/${item.productId}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      ProductImage(
                        path: item.imageUrl,
                        width: 92,
                        height: 108,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: AppColors.brand.withValues(alpha: 0.85),
                          child: Text(
                            s.sizeLabel(
                              item.size == AppConstants.fabricStockUnit
                                  ? s.meter
                                  : item.size,
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 108,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  height: 1.25,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                notifier.removeItem(item.key);
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: item.shopOwnerId.trim().isEmpty
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  openShopStorefront(
                                    context,
                                    shopOwnerId: item.shopOwnerId,
                                    shopName: item.shopName,
                                  );
                                },
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            item.shopName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              color: item.shopOwnerId.trim().isEmpty
                                  ? AppColors.textTertiary
                                  : AppColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              Formatters.price(item.lineTotal),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w900,
                                color: AppColors.brand,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            _QuantityControl(
                              quantity: item.quantity,
                              onMinus: () {
                                HapticFeedback.selectionClick();
                                notifier.updateQuantity(
                                  item.key,
                                  item.quantity - 1,
                                );
                              },
                              onPlus: () {
                                HapticFeedback.selectionClick();
                                notifier.updateQuantity(
                                  item.key,
                                  item.quantity + 1,
                                );
                              },
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
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QuantityControl({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove_rounded, onTap: onMinus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _QtyBtn(
            icon: Icons.add_rounded,
            onTap: onPlus,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _QtyBtn({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.brand : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 16,
            color: filled ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CheckoutBar extends ConsumerWidget {
  final int itemCount;
  final double total;
  final bool canCheckout;
  final bool pendingAccount;
  final bool guestCheckout;
  final VoidCallback onCheckout;
  final VoidCallback onContinue;

  const _CheckoutBar({
    required this.itemCount,
    required this.total,
    required this.canCheckout,
    required this.pendingAccount,
    this.guestCheckout = false,
    required this.onCheckout,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final bottom =
        MediaQuery.of(context).padding.bottom + kPremiumBottomNavClearance;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (guestCheckout) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                s.loginToCheckout,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else if (!canCheckout && pendingAccount) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.highlight.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.highlight.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                s.pendingCannotOrder,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.highlight,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.brand.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              s.deliveryFeeNote,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: s.itemCount,
                  value: '$itemCount',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: s.total,
                  value: Formatters.price(total),
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: canCheckout ? AppColors.ctaGradient : null,
                color: canCheckout
                    ? null
                    : AppColors.textTertiary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
                boxShadow: canCheckout
                    ? [
                        BoxShadow(
                          color: AppColors.highlight.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      guestCheckout
                          ? Icons.login_rounded
                          : canCheckout
                              ? Icons.lock_outline_rounded
                              : Icons.hourglass_top_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      guestCheckout
                          ? s.loginToOrder
                          : canCheckout
                              ? s.checkout
                              : s.waitingApproval,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onContinue,
            child: Text(
              s.continueShopping,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: emphasize ? 15 : 13,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: emphasize ? 20 : 14,
              fontWeight: FontWeight.w900,
              color: emphasize ? AppColors.brand : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _IosLiquidGlassAlert extends ConsumerWidget {
  const _IosLiquidGlassAlert();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassFill = isDark
        ? [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.08),
          ]
        : [
            Colors.white.withValues(alpha: 0.62),
            Colors.white.withValues(alpha: 0.38),
          ];
    final rim = isDark
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.78);
    final titleColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF3A3A3C);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: glassFill,
                ),
                border: Border.all(color: rim, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 24,
                    right: 24,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: isDark ? 0.45 : 0.9),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                        decorationThickness: 0,
                        color: titleColor,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.45),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: isDark ? 0.22 : 0.7,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 30,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : AppColors.brand,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            s.locationNotSet,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                              letterSpacing: -0.3,
                              height: 1.25,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.locationRequiredBody,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: bodyColor,
                              height: 1.45,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            height: 0.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.brand,
                                textStyle: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: Text(s.setLocation),
                            ),
                          ),
                          Container(
                            height: 0.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : const Color(0xFF8E8E93),
                                textStyle: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text(s.later),
                            ),
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
      ),
    );
  }
}

class _CheckoutAddressSheet extends ConsumerWidget {
  final List<AddressModel> addresses;

  const _CheckoutAddressSheet({required this.addresses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final defaultId = addresses
        .firstWhere((a) => a.isDefault, orElse: () => addresses.first)
        .id;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
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
          const SizedBox(height: 16),
          Text(
            s.chooseDeliveryAddress,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.whichAddress,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final address = addresses[index];
                final isDefault = address.id == defaultId;
                return Material(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, address),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDefault
                              ? AppColors.brand.withValues(alpha: 0.45)
                              : AppColors.border.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDefault
                                ? Icons.home_rounded
                                : Icons.location_on_outlined,
                            color: AppColors.brand,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        address.label,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14.5,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isDefault)
                                      Text(
                                        s.primary,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.brand,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address.location,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings/addresses');
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(
              s.addNewAddress,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
          ),
        ],
      ),
    );
  }
}
