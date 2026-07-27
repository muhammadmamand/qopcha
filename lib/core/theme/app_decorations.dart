import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppDecorations {
  static BoxDecoration card({double radius = 24, Color? color}) => BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: softShadow,
      );

  static BoxDecoration glass({double radius = 20}) => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      );

  static BoxDecoration gradientCard() => BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      );

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.18),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];
}
