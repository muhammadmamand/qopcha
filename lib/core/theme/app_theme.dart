import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_color_theme.dart';

class AppColors {
  // Brand mix: ~60% white · ~30% brand · ~10% highlight
  // Mutable so users can switch color packs from Settings.
  static Color brand = const Color(0xFF116C71);
  static Color highlight = const Color(0xFFF15C22);
  static const brandWhite = Color(0xFFFFFFFF);

  static Color primary = const Color(0xFF0F0F14);
  static Color secondary = brand;
  static Color secondaryLight = const Color(0xFF2A9AA3);
  static const accent = Color(0xFF2A2A38);
  static const gold = Color(0xFFC9A87C);
  static const success = Color(0xFF2D9B6A);
  static Color warning = highlight;
  static const error = Color(0xFFD64550);
  static Color gradientStart = const Color(0xFF0D3D42);
  static Color gradientMid = brand;
  static Color gradientEnd = const Color(0xFF0A555C);

  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStart, gradientMid, gradientEnd],
      );

  static LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [secondaryLight, brand],
      );

  static LinearGradient get ctaGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(highlight, Colors.white, 0.18) ?? highlight,
          highlight,
        ],
      );

  // ---- Theme-aware semantic colors ----
  // These are swapped at runtime by [applyBrightness] so hardcoded usages
  // across screens correctly reflect light/dark mode.
  static Color surface = _lightSurface;
  static Color surfaceVariant = _lightSurfaceVariant;
  static Color card = _lightCard;
  static Color textPrimary = _lightTextPrimary;
  static Color textSecondary = _lightTextSecondary;
  static Color textTertiary = _lightTextTertiary;
  static Color border = _lightBorder;
  static Color shimmerBase = _lightSurfaceVariant;
  static Color shimmerHighlight = _lightSurface;

  static const _lightSurface = brandWhite;
  static const _lightSurfaceVariant = Color(0xFFEFF5F5); // soft teal wash
  static const _lightCard = brandWhite;
  static const _lightTextPrimary = Color(0xFF0F0F14);
  static const _lightTextSecondary = Color(0xFF5A6A6C);
  static const _lightTextTertiary = Color(0xFF8A9A9C);
  static const _lightBorder = Color(0xFFDCE6E7);

  static const _darkSurface = Color(0xFF0C1415);
  static const _darkSurfaceVariant = Color(0xFF152224);
  static const _darkCard = Color(0xFF1A2628);
  static const _darkTextPrimary = Color(0xFFF3F7F7);
  static const _darkTextSecondary = Color(0xFFB0C0C2);
  static const _darkTextTertiary = Color(0xFF7A8A8C);
  static const _darkBorder = Color(0xFF2A3A3C);

  /// On-brand solid white (buttons, icons on teal). Never changes with theme.
  static const onBrand = Color(0xFFFFFFFF);

  /// Sheet / dialog / nav fill — follows light/dark.
  static Color sheet = _lightCard;

  static Brightness _brightness = Brightness.light;
  static AppColorTheme _colorTheme = AppColorTheme.teal;
  static bool get isDark => _brightness == Brightness.dark;
  static AppColorTheme get colorTheme => _colorTheme;

  static void applyColorTheme(AppColorTheme theme) {
    _colorTheme = theme;
    brand = theme.brand;
    highlight = theme.highlight;
    secondary = theme.brand;
    secondaryLight = theme.brandLight;
    warning = theme.highlight;
    gradientStart = theme.gradientStart;
    gradientMid = theme.brand;
    gradientEnd = theme.gradientEnd;
  }

  static void applyBrightness(Brightness brightness) {
    _brightness = brightness;
    final dark = brightness == Brightness.dark;
    surface = dark ? _darkSurface : _lightSurface;
    surfaceVariant = dark ? _darkSurfaceVariant : _lightSurfaceVariant;
    card = dark ? _darkCard : _lightCard;
    sheet = dark ? _darkCard : _lightCard;
    textPrimary = dark ? _darkTextPrimary : _lightTextPrimary;
    textSecondary = dark ? _darkTextSecondary : _lightTextSecondary;
    textTertiary = dark ? _darkTextTertiary : _lightTextTertiary;
    border = dark ? _darkBorder : _lightBorder;
    shimmerBase = dark ? _darkSurfaceVariant : _lightSurfaceVariant;
    shimmerHighlight = dark ? _darkCard : _lightSurface;
  }
}

class AppTheme {
  static const fontFamily = 'Rabar';

  static TextTheme _textTheme(TextTheme base, {required Color primary}) {
    TextStyle style(TextStyle? s, {FontWeight? weight, Color? color, double? letterSpacing, double? height}) {
      return (s ?? const TextStyle()).copyWith(
        fontFamily: fontFamily,
        fontWeight: weight ?? s?.fontWeight,
        color: color ?? s?.color ?? primary,
        letterSpacing: letterSpacing ?? s?.letterSpacing,
        height: height ?? s?.height,
      );
    }

    return base.copyWith(
      displayLarge: style(base.displayLarge, weight: FontWeight.w800, letterSpacing: -0.5),
      displayMedium: style(base.displayMedium, weight: FontWeight.w800),
      displaySmall: style(base.displaySmall, weight: FontWeight.w700),
      headlineLarge: style(base.headlineLarge, weight: FontWeight.w800),
      headlineMedium: style(base.headlineMedium, weight: FontWeight.w700, letterSpacing: -0.3),
      headlineSmall: style(base.headlineSmall, weight: FontWeight.w700),
      titleLarge: style(base.titleLarge, weight: FontWeight.w600),
      titleMedium: style(base.titleMedium, weight: FontWeight.w600),
      titleSmall: style(base.titleSmall, weight: FontWeight.w600),
      bodyLarge: style(base.bodyLarge, height: 1.5),
      bodyMedium: style(base.bodyMedium, color: AppColors.textSecondary, height: 1.5),
      bodySmall: style(base.bodySmall),
      labelLarge: style(base.labelLarge, weight: FontWeight.w600, letterSpacing: 0.2),
      labelMedium: style(base.labelMedium, weight: FontWeight.w600),
      labelSmall: style(base.labelSmall, weight: FontWeight.w600),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
    );

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.secondary,
        primary: AppColors.secondary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme(base.textTheme, primary: AppColors.textPrimary),
      primaryTextTheme: _textTheme(base.primaryTextTheme, primary: AppColors.textPrimary),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textTertiary,
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.secondary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          minimumSize: const Size(64, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: AppColors.border),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.secondary.withValues(alpha: 0.12),
        labelStyle: const TextStyle(fontFamily: fontFamily, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.highlight,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
    );
    final darkScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.secondary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.secondaryLight,
          secondary: AppColors.secondary,
          tertiary: AppColors.highlight,
          surface: AppColors._darkCard,
          onSurface: AppColors._darkTextPrimary,
        );

    return base.copyWith(
      colorScheme: darkScheme,
      scaffoldBackgroundColor: AppColors._darkSurface,
      canvasColor: AppColors._darkSurface,
      textTheme: _textTheme(
        base.textTheme,
        primary: AppColors._darkTextPrimary,
      ),
      primaryTextTheme: _textTheme(
        base.primaryTextTheme,
        primary: AppColors._darkTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors._darkTextPrimary,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors._darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors._darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors._darkCard,
        modalBackgroundColor: AppColors._darkCard,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors._darkCard,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors._darkBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors._darkSurfaceVariant,
      ),
    );
  }
}
