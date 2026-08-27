import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

/// Promo-style card matching the VIP “تایبەت بۆ تۆ” mock — shown when the
/// customer has a standing discount (admin) or product offers.
class SpecialDiscountBanner extends StatelessWidget {
  final double productPercent;
  final double deliveryPercent;
  final VoidCallback? onShopNow;

  const SpecialDiscountBanner({
    super.key,
    this.productPercent = 0,
    this.deliveryPercent = 0,
    this.onShopNow,
  });

  bool get visible => productPercent > 0 || deliveryPercent > 0;

  String get _headline {
    if (productPercent > 0) {
      return '%${productPercent.round()} داشکاندن';
    }
    return '%${deliveryPercent.round()} داشکانی گەیاندن';
  }

  String get _subtitle {
    if (productPercent > 0 && deliveryPercent > 0) {
      return 'جل + گەیاندن ${deliveryPercent.round()}%';
    }
    if (productPercent > 0) return 'لە داواکاری داهاتووت';
    return 'لە کرێی گەیاندنی داهاتووت';
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    // Keep mock layout (teal on the right) regardless of app language.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onShopNow == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onShopNow!();
                },
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 148,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Row(
                children: [
                // Teal copy block (right side in RTL).
                Expanded(
                  flex: 58,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Color(0xFF146B72),
                          Color(0xFF0F555B),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تایبەت بۆ تۆ',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                          const Spacer(),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ئێستا بکڕە',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: AppColors.brand,
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
                // Light graphic block with tag + hanger watermark.
                Expanded(
                  flex: 42,
                  child: ColoredBox(
                    color: const Color(0xFFF3F4F6),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          left: -8,
                          bottom: -18,
                          child: Icon(
                            Icons.checkroom_rounded,
                            size: 118,
                            color: const Color(0xFFD1D5DB)
                                .withValues(alpha: 0.85),
                          ),
                        ),
                        Positioned(
                          top: 28,
                          left: 0,
                          right: 0,
                          child: Icon(
                            Icons.sell_rounded,
                            size: 46,
                            color: AppColors.highlight,
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
