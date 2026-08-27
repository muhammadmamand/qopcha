import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Premium product-details design tokens (RTL / Kurdish).
///
/// Every surface/text token proxies [AppColors] so the page follows the active
/// light/dark mode and the color pack chosen in Settings.
abstract final class PdColors {
  /// Fixed white for content sitting on brand/accent fills.
  static const white = Color(0xFFFFFFFF);

  static Color get primary => AppColors.brand;
  static Color get accent => AppColors.highlight;

  /// Page background behind the content sheet.
  static Color get canvas => AppColors.surface;

  /// Raised surfaces: content sheet, cards, bottom bar.
  static Color get card => AppColors.card;

  /// Recessed fills: chips, image placeholders, quantity stepper.
  static Color get gray => AppColors.surfaceVariant;

  static Color get text => AppColors.textPrimary;
  static Color get textSecondary => AppColors.textSecondary;
  static Color get textTertiary => AppColors.textTertiary;
  static Color get border => AppColors.border;

  static const star = Color(0xFFF5A623);
}

abstract final class PdTheme {
  static TextStyle display({
    double size = 22,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.35,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? PdColors.text,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.6,
  }) =>
      TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? PdColors.textSecondary,
        height: height,
      );

  static TextStyle label({
    double size = 13,
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? PdColors.text,
      );

  /// Shadows need more punch on dark backgrounds to stay visible.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: AppColors.isDark ? 0.5 : 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: AppColors.isDark ? 0.4 : 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
