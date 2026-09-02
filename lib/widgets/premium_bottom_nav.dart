import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../core/theme/app_theme.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Space screens should leave above the floating glass bar.
const double kPremiumBottomNavClearance = 100;

/// Liquid-glass bottom nav — must extend [LiquidGlassTabBar] so
/// [LiquidGlassScaffold] enables the glass-pill pipeline (refraction,
/// sliding pill, press-and-hold drag between tabs).
class PremiumBottomNav extends LiquidGlassTabBar {
  PremiumBottomNav._({
    required super.items,
    required super.selectedIndex,
    required super.onChanged,
    required super.width,
    required super.style,
    required super.itemStyle,
    required super.pillStyle,
    super.key,
  }) : super(
          height: _barHeight,
          itemPadding: 3,
          margin: const EdgeInsets.only(bottom: _bottomMargin),
        );

  factory PremiumBottomNav({
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onTap,
    required List<NavItem> items,
    List<int?> badges = const [],
    List<int> animatedIndexes = const [],
    required BuildContext context,
  }) {
    if (items.isEmpty) {
      throw ArgumentError('PremiumBottomNav requires at least one item.');
    }

    final dark = AppColors.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final barWidth =
        (screenWidth - _horizontalInset * 2).clamp(280.0, 560.0);
    final ink = dark ? const Color(0xFFF3F7F7) : const Color(0xFF121215);
    final pillShape = _glassShape(_pillRadius, dark);

    return PremiumBottomNav._(
      key: key,
      items: [
        for (var i = 0; i < items.length; i++)
          _tabItem(
            items[i],
            badge: i < badges.length ? badges[i] : null,
          ),
      ],
      selectedIndex: currentIndex,
      onChanged: onTap,
      width: barWidth,
      style: LiquidGlassStyle(
        shape: _glassShape(_barHeight / 2, dark),
        appearance: LiquidGlassAppearance(
          color: dark
              ? const Color(0x66181C1E)
              : const Color(0x8FFFFFFF),
          blur: const LiquidGlassBlur(sigmaX: 5, sigmaY: 5),
          shadow: LiquidGlassShadow(
            blur: 9,
            opacity: dark ? 0.18 : 0.13,
          ),
        ),
        refraction: const LiquidGlassRefraction(
          distortion: 0.06,
          distortionWidth: 26,
        ),
      ),
      itemStyle: LiquidGlassTabItemStyle(
        selectedColor: _selectedGreen,
        unselectedColor: ink,
        iconSize: _iconRest,
        labelFontSize: 10,
        iconLabelGap: 2,
        underGlassIconSize: 30,
        underGlassLabelFontSize: 10,
        selectedFontWeight: FontWeight.w700,
        unselectedFontWeight: FontWeight.w600,
      ),
      pillStyle: LiquidGlassTabPillStyle(
        mode: LiquidGlassPillMode.both,
        animated: true,
        animationDuration: const Duration(milliseconds: 420),
        animationCurve: Curves.easeInOutCubic,
        show: true,
        growHeight: 8,
        // Softer spring — slower glide, no bounce on landing.
        travelStiffness: 175,
        travelDamping: 30,
        shape: pillShape,
        glassStyle: LiquidGlassStyle(
          shape: pillShape,
          appearance: const LiquidGlassAppearance(
            color: Colors.transparent,
            shadow: LiquidGlassShadow(blur: 9, opacity: 0.3),
          ),
          refraction: const LiquidGlassRefraction(
            distortion: 0.06,
            distortionWidth: 14,
            chromaticAberration: 0.002,
          ),
        ),
        rest: LiquidGlassStyle(
          shape: pillShape,
          appearance: LiquidGlassAppearance(
            color: dark
                ? const Color(0x33FFFFFF)
                : const Color(0x2EAEAEB2),
          ),
        ),
        motion: const LiquidGlassLensMotionSpec(
          sampleWindow: 0.42,
          sensitivity: 0.000055,
          maxDeformation: 0.09,
          responseTime: 0.22,
        ),
      ),
    );
  }

  /// Selected tab green — Qopcha brand teal-green.
  static final _selectedGreen = AppColors.brand;

  static const _barHeight = 60.0;
  static const _iconRest = 24.0;
  static const _horizontalInset = 16.0;
  static const _bottomMargin = 22.0;
  static const _pillRadius = 28.0;

  static LiquidGlassShape _glassShape(double cornerRadius, bool dark) {
    return LiquidGlassShape.continuousRoundedRectangle(
      cornerRadius: cornerRadius,
      clipQuality: LiquidGlassClipQuality.exact,
      borderWidth: 0.7,
      lightIntensity: dark ? 0.75 : 0.9,
      lightDirection: 62,
      borderType: OpticalBorder(
        borderSaturation: dark ? 1.0 : 1.1,
        ambientIntensity: dark ? 0.7 : 0.85,
        borderSolidity: 0.95,
      ),
    );
  }

  static LiquidGlassTabBarItem _tabItem(
    NavItem item, {
    int? badge,
  }) {
    return LiquidGlassTabBarItem(
      label: item.label,
      iconBuilder: (context, glyph) {
        final icon = Icon(
          glyph.selected ? item.activeIcon : item.icon,
          size: glyph.size,
          color: glyph.color,
          shadows: glyph.selected
              ? [
                  Shadow(
                    color: glyph.color.withValues(alpha: 0.85),
                    blurRadius: 14,
                  ),
                ]
              : null,
        );

        if (badge == null || badge <= 0) return icon;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            icon,
            Positioned(
              right: -10,
              top: -8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
