import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../../widgets/product_image.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    final location = user?.location?.trim() ?? '';

    if (location.isEmpty) {
      if (!context.mounted) return;
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

      if (goSetLocation == true && context.mounted) {
        context.push('/settings/edit-profile');
      }
      return;
    }

    final items = ref.read(cartProvider);
    final order = await ref.read(ordersProvider.notifier).placeOrder(items);
    if (order == null) return;

    await ref.read(cartProvider.notifier).clear();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'داواکاریەکەت بە سەرکەوتوویی ناردرا',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
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

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.brandWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'سڕینەوەی سەبەتە؟',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'هەموو بەرهەمەکان لە سەبەتە دەسڕدرێنەوە.',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('پاشگەزبوونەوە'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('سڕینەوە'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(cartProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final count = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.brandWhite,
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
                      AppColors.brandWhite.withValues(alpha: 0),
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
                              'سەبەتە',
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
                                  ? 'هیچ بەرهەمێک نییە'
                                  : '$count دانە لە سەبەتەدا',
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
                          onPressed: () => _confirmClear(context, ref),
                          icon: Icon(
                            Icons.delete_sweep_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          label: Text(
                            'پاککردنەوە',
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
              onCheckout: () => _checkout(context, ref),
              onContinue: () => context.go('/home'),
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 12, 40, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brand.withValues(alpha: 0.16),
                    AppColors.highlight.withValues(alpha: 0.10),
                  ],
                ),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: AppColors.brand,
              ),
            )
                .animate()
                .fadeIn(duration: 420.ms)
                .scale(
                  begin: const Offset(0.88, 0.88),
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 24),
            Text(
              'سەبەتەکەت بەتاڵە',
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
              'بەرهەمێک زیاد بکە و کڕینەکەت تەواو بکە',
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
                label: const Text(
                  'گەڕانەوە بۆ فرۆشگا',
                  style: TextStyle(
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
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandWhite,
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
                            'قیاس ${item.size}',
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
                        Text(
                          item.shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
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

class _CheckoutBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onCheckout;
  final VoidCallback onContinue;

  const _CheckoutBar({
    required this.itemCount,
    required this.total,
    required this.onCheckout,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.of(context).padding.bottom + kPremiumBottomNavClearance;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
      decoration: BoxDecoration(
        color: AppColors.brandWhite,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'ژمارەی دانە',
                  value: '$itemCount',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'کۆی گشتی',
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
                gradient: AppColors.ctaGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.highlight.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'تەواوکردنی کڕین',
                      style: TextStyle(
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
              'بەردەوامبوون لە کڕین',
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

class _IosLiquidGlassAlert extends StatelessWidget {
  const _IosLiquidGlassAlert();

  @override
  Widget build(BuildContext context) {
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
                            'شوێن دیاری نەکراوە',
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
                            'بۆ تەواوکردنی داواکاری، تکایە شوێنی خۆت دیاری بکە.',
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
                              child: const Text('دیاریکردنی شوێن'),
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
                              child: const Text('دواتر'),
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
