import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../core/theme/app_color_theme.dart';
import '../core/theme/app_theme.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  /// Optional asset glyph (e.g. fabric roll). Tint follows tab color.
  final String? assetIcon;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.assetIcon,
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

  /// The glass pill positions tabs in LTR geometry; wrap so RTL locales
  /// keep Home on the right without breaking the selection indicator.
  static Widget _ltrBar(Widget child) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ltrBar(super.build(context));
  }

  @override
  Widget buildGlassPillBar({
    required Widget body,
    Widget? outerChild,
    Color? backgroundColor,
    double bottomInset = 0,
    double pixelRatio = 1.0,
    bool useSync = true,
    bool? useImpellerBackdrop,
    bool realTimeCapture = true,
    bool outerNeedsRealtime = false,
    LiquidGlassAdaptiveSampling? adaptiveSampling,
    LiquidGlassAdaptiveSampling? outerAdaptiveSampling,
    LiquidGlassAdaptivity? areaAdaptivity,
    LiquidGlassAdaptivityLink? areaLink,
    LiquidGlassSystemChrome systemChrome = LiquidGlassSystemChrome.none,
  }) {
    return _ltrBar(
      super.buildGlassPillBar(
        body: body,
        outerChild: outerChild,
        backgroundColor: backgroundColor,
        // Liquid glass asserts padding >= 0; clamp in case MediaQuery
        // briefly reports a bad inset while a modal is opening.
        bottomInset: bottomInset < 0 ? 0 : bottomInset,
        pixelRatio: pixelRatio,
        useSync: useSync,
        useImpellerBackdrop: useImpellerBackdrop,
        realTimeCapture: realTimeCapture,
        outerNeedsRealtime: outerNeedsRealtime,
        adaptiveSampling: adaptiveSampling,
        outerAdaptiveSampling: outerAdaptiveSampling,
        areaAdaptivity: areaAdaptivity,
        areaLink: areaLink,
        systemChrome: systemChrome,
      ),
    );
  }

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
    final theme = AppColors.colorTheme;
    final selected = AppColors.brand;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final barWidth =
        (screenWidth - _horizontalInset * 2).clamp(280.0, 560.0);
    final ink = dark ? const Color(0xFFF3F7F7) : const Color(0xFF121215);
    final pillShape = _glassShape(_pillRadius, dark);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final displayItems = isRtl ? items.reversed.toList() : items;
    final displayBadges = isRtl && badges.isNotEmpty
        ? List<int?>.from(badges.reversed)
        : badges;
    final barSelectedIndex =
        isRtl ? items.length - 1 - currentIndex : currentIndex;
    void barOnChanged(int index) {
      onTap(isRtl ? items.length - 1 - index : index);
    }

    return PremiumBottomNav._(
      key: key ?? ValueKey('nav-${theme.name}-$dark'),
      items: [
        for (var i = 0; i < displayItems.length; i++)
          _tabItem(
            displayItems[i],
            badge: i < displayBadges.length ? displayBadges[i] : null,
          ),
      ],
      selectedIndex: barSelectedIndex,
      onChanged: barOnChanged,
      width: barWidth,
      style: LiquidGlassStyle(
        shape: _glassShape(_barHeight / 2, dark),
        appearance: LiquidGlassAppearance(
          color: _barTint(dark, theme),
          blur: const LiquidGlassBlur(sigmaX: 5, sigmaY: 5),
          shadow: LiquidGlassShadow(
            blur: 9,
            opacity: dark ? 0.18 : 0.13,
            color: theme.isFloral
                ? selected.withValues(alpha: 0.35)
                : Colors.black,
          ),
        ),
        refraction: const LiquidGlassRefraction(
          distortion: 0.06,
          distortionWidth: 26,
        ),
      ),
      itemStyle: LiquidGlassTabItemStyle(
        selectedColor: selected,
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
            color: theme.isFloral
                ? selected.withValues(alpha: dark ? 0.24 : 0.20)
                : dark
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

  static const _barHeight = 60.0;
  static const _iconRest = 24.0;
  static const _horizontalInset = 16.0;
  static const _bottomMargin = 22.0;
  static const _pillRadius = 28.0;

  static Color _barTint(bool dark, AppColorTheme theme) {
    if (dark) {
      return theme.isFloral
          ? Color.alphaBlend(
              theme.brand.withValues(alpha: 0.22),
              const Color(0x66181C1E),
            )
          : const Color(0x66181C1E);
    }
    if (theme.isFloral) {
      return Color.alphaBlend(
        theme.brand.withValues(alpha: 0.16),
        const Color(0x8FFFFFFF),
      );
    }
    return const Color(0x8FFFFFFF);
  }

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
        final Widget icon = item.assetIcon != null
            ? ColorFiltered(
                colorFilter: ColorFilter.mode(glyph.color, BlendMode.srcIn),
                child: Image.asset(
                  item.assetIcon!,
                  width: glyph.size,
                  height: glyph.size,
                  fit: BoxFit.contain,
                ),
              )
            : Icon(
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
