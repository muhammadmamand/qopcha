import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import 'pd_theme.dart';

class BottomActionBar extends StatelessWidget {
  final ValueNotifier<int> quantity;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final int minQty;
  final int maxQty;

  const BottomActionBar({
    super.key,
    required this.quantity,
    required this.onAddToCart,
    required this.onBuyNow,
    this.minQty = 1,
    this.maxQty = 20,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: BoxDecoration(
        color: PdColors.card,
        border: Border(
          top: BorderSide(color: PdColors.border.withValues(alpha: 0.7)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark ? 0.45 : 0.07,
            ),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Row(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: quantity,
            builder: (context, qty, _) {
              return Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: PdColors.gray,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: PdColors.border.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    _QtyBtn(
                      icon: Icons.remove_rounded,
                      enabled: qty > minQty,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (qty > minQty) quantity.value = qty - 1;
                      },
                    ),
                    SizedBox(
                      width: 26,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Text(
                          '$qty',
                          key: ValueKey(qty),
                          textAlign: TextAlign.center,
                          style: PdTheme.label(
                            size: 15,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    _QtyBtn(
                      icon: Icons.add_rounded,
                      enabled: qty < maxQty,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (qty < maxQty) quantity.value = qty + 1;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),

          // Icon-only cart button leaves room for a full-width primary action.
          Material(
            color: PdColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                onAddToCart();
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PdColors.primary.withValues(alpha: 0.5),
                    width: 1.4,
                  ),
                ),
                child: Icon(
                  Icons.add_shopping_cart_rounded,
                  size: 21,
                  color: PdColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onBuyNow();
                },
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: PdColors.primary.withValues(alpha: 0.34),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'ئێستا بیکڕە',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PdTheme.label(
                        size: 15,
                        weight: FontWeight.w900,
                        color: PdColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _QtyBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 46,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? PdColors.text : PdColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
