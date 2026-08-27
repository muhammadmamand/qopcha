import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_theme.dart';

/// Looping packing animation while the shop prepares an accepted order.
class OrderPreparingAnimation extends StatelessWidget {
  final String? shopName;
  final bool compact;

  const OrderPreparingAnimation({
    super.key,
    this.shopName,
    this.compact = false,
  });

  static const asset = 'assets/lottie/order_packed.json';

  @override
  Widget build(BuildContext context) {
    final shop = (shopName ?? '').trim();
    final size = compact ? 88.0 : 112.0;
    final body = shop.isEmpty
        ? 'دووکان جلەکە دەپێچێتەوە و ئامادەی دەکات'
        : 'دووکانی $shop جلەکە دەپێچێتەوە و ئامادەی دەکات';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 10,
        compact ? 6 : 8,
        compact ? 12 : 14,
        compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            AppColors.highlight.withValues(alpha: AppColors.isDark ? 0.16 : 0.12),
            AppColors.brand.withValues(alpha: AppColors.isDark ? 0.16 : 0.10),
          ],
        ),
        border: Border.all(
          color: AppColors.highlight.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Lottie.asset(
              asset,
              fit: BoxFit.contain,
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.inventory_2_rounded,
                  size: size * 0.45,
                  color: AppColors.brand,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ئامادە دەکرێت',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 13 : 14.5,
                        color: AppColors.highlight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const _BusyDots(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _BusyDots extends StatelessWidget {
  const _BusyDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 3),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.highlight,
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(delay: (i * 180).ms, duration: 280.ms)
                .then(delay: 220.ms)
                .fadeOut(duration: 280.ms),
          ),
      ],
    );
  }
}
