import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassy_real_navbar/glassy_real_navbar.dart';

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
const double kPremiumBottomNavClearance = 92;

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final List<int?> badges;
  final List<int> animatedIndexes;

  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.badges = const [],
    this.animatedIndexes = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final dark = AppColors.isDark;

    // Pad outside the package bar. GlassNavBar measures lens position from
    // its parent width, so an inner `margin` pushes the lens past the last icon.
    return Padding(
      padding: EdgeInsets.fromLTRB(28, 0, 28, 10 + bottomInset),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GlassNavBar(
          selectedIndex: currentIndex,
          onItemSelected: (index) {
            if (index == currentIndex) return;
            HapticFeedback.selectionClick();
            onTap(index);
          },
          height: 54,
          blur: 24,
          opacity: 0.14,
          refraction: 1.42,
          lensRefraction: 1.0,
          lensBlur: 0,
          lensVelocityRefraction: 0,
          backgroundColor: Colors.white,
          selectedItemColor:
              dark ? Colors.white : const Color(0xFF1C1C1E),
          unselectedItemColor: dark
              ? Colors.white.withValues(alpha: 0.48)
              : const Color(0xFF1C1C1E).withValues(alpha: 0.38),
          lensBorderColor: Colors.white.withValues(alpha: 0.72),
          showLabels: false,
          borderRadius: BorderRadius.circular(27),
          lensWidth: 62,
          lensHeight: 48,
          lensBorderRadius: BorderRadius.circular(24),
          glassiness: 1.25,
          barGlassiness: 1.25,
          lensMotionBlurStrength: 0,
          animationEffect: GlassAnimation.heavyGlass,
          activeItemAnimation: GlassActiveItemAnimation.none,
          margin: EdgeInsets.zero,
          itemIconSize: 22,
          items: [
            for (var i = 0; i < items.length; i++)
              GlassNavBarItem(
                icon: items[i].icon,
                activeIcon: items[i].activeIcon,
                title: items[i].label,
                semanticLabel: items[i].label,
                badge: i < badges.length ? badges[i] : null,
                badgeColor: AppColors.highlight,
              ),
          ],
        ),
      ),
    );
  }
}
