import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// visionOS-like frosted panel used across Spatial UI screens.
class SpatialGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final bool selected;
  final bool float;
  final double? width;
  final double? height;
  final BoxShape shape;
  final AlignmentGeometry? alignment;

  const SpatialGlass({
    super.key,
    required this.child,
    this.radius = 26,
    this.padding,
    this.selected = false,
    this.float = false,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final fill = selected
        ? [
            Colors.white.withValues(alpha: dark ? 0.28 : 0.48),
            Colors.white.withValues(alpha: dark ? 0.10 : 0.18),
          ]
        : [
            Colors.white.withValues(alpha: dark ? 0.12 : 0.26),
            Colors.white.withValues(alpha: dark ? 0.04 : 0.08),
          ];
    final radiusGeo = shape == BoxShape.circle
        ? BorderRadius.circular(99)
        : BorderRadius.circular(radius);

    final panel = ClipRRect(
      borderRadius: radiusGeo,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: float ? 36 : 18,
          sigmaY: float ? 36 : 18,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          alignment: alignment,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.circle ? null : radiusGeo,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: fill,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? 0.22 : 0.55),
              width: 0.6,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (!float) return panel;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radiusGeo,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.14),
            blurRadius: 48,
            offset: const Offset(0, 22),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.18 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: panel,
    );
  }
}

/// Dim radial atmosphere + blurred brand / highlight orbs.
class SpatialScene extends StatelessWidget {
  final Widget child;

  const SpatialScene({super.key, required this.child});

  static Color get backgroundColor =>
      AppColors.isDark ? const Color(0xFF070B10) : const Color(0xFFD5DEE3);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.55),
                  radius: 1.15,
                  colors: AppColors.isDark
                      ? [
                          AppColors.brand.withValues(alpha: 0.28),
                          const Color(0xFF070B10),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.55),
                          const Color(0xFFC9D5DB),
                        ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -40,
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brand.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          left: -90,
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.highlight.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class SpatialCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const SpatialCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 36,
  });

  @override
  Widget build(BuildContext context) {
    return SpatialGlass(
      float: true,
      radius: radius,
      padding: padding,
      child: child,
    );
  }
}

class SpatialSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const SpatialSectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          SpatialGlass(
            width: 34,
            height: 34,
            radius: 12,
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppColors.brand),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
