import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(8, top + 6, 16, 18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'شێوازەکانی پارەدان',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'FIB و FastPay بەم زووانە زیاد دەکرێن',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 24 + bottom),
              physics: const BouncingScrollPhysics(),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.highlight.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.highlight.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.highlight,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ئێستا تەنها پارەدان لە کاتی گەیاندن بەردەستە. '
                          'FIB و FastPay بۆ ماوەیەکی کاتی ناکارا کراون.',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'بەردەست ئێستا',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                _PaymentMethodTile(
                  title: 'پارەدان لە کاتی گەیاندن',
                  subtitle: 'پارەکە بە شۆفێر دەدەیت کاتێک داواکاری دەگات',
                  brandColor: AppColors.brand,
                  initials: 'COD',
                  enabled: true,
                ),
                const SizedBox(height: 22),
                Text(
                  'بەم زووانە زیاد دەکرێت',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                const _PaymentMethodTile(
                  title: 'FIB',
                  subtitle: 'پارەدان لە ڕێگای First Iraqi Bank',
                  brandColor: Color(0xFF15988E),
                  initials: 'FIB',
                  logoAsset: 'assets/images/fib_logo.jpg',
                  enabled: false,
                  comingSoonLabel: 'بەم زووانە زیاد دەکرێت',
                ),
                const SizedBox(height: 12),
                const _PaymentMethodTile(
                  title: 'FastPay',
                  subtitle: 'پارەدانی خێرا لە ڕێگای FastPay',
                  brandColor: Color(0xFFE85D04),
                  initials: 'FP',
                  logoAsset: 'assets/images/fastpay_logo.png',
                  enabled: false,
                  comingSoonLabel: 'بەم زووانە زیاد دەکرێت',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String initials;
  final Color brandColor;
  final bool enabled;
  final String? comingSoonLabel;
  final String? logoAsset;

  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.initials,
    required this.brandColor,
    required this.enabled,
    this.comingSoonLabel,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.72;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: enabled
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        comingSoonLabel ?? 'بەم زووانە زیاد دەکرێت',
                        style: const TextStyle(fontFamily: AppTheme.fontFamily),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.brand,
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: enabled
                    ? AppColors.brand.withValues(alpha: 0.28)
                    : AppColors.border.withValues(alpha: 0.75),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: logoAsset != null
                        ? Colors.transparent
                        : brandColor.withValues(alpha: enabled ? 0.14 : 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: brandColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: logoAsset != null
                      ? Image.asset(
                          logoAsset!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        )
                      : Text(
                          initials,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: brandColor,
                          ),
                        ),
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
                              title,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!enabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textTertiary
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'ناکارا',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brand.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'چالاک',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brand,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (!enabled && comingSoonLabel != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: AppColors.highlight,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                comingSoonLabel!,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.highlight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
