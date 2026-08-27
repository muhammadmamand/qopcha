import 'package:flutter/material.dart';
import 'glass_animation.dart';

/// Helper extension to use withValues instead of deprecated withOpacity
extension _ColorAlpha on Color {
  Color withAlpha2(double opacity) =>
      withValues(alpha: opacity.clamp(0.0, 1.0));
}

/// Pre-built theme presets for [GlassNavBar].
///
/// These presets provide complete styling configurations optimized for
/// different app aesthetics and use cases.
///
/// Example:
/// ```dart
/// final theme = GlassNavBarPreset.cyberpunk.theme;
/// GlassNavBar(
///   // Apply theme properties...
/// )
/// ```
enum GlassNavBarPreset {
  /// Clean, subtle, iOS-inspired design.
  ///
  /// Features:
  /// - Light background with soft blur
  /// - Minimal lens effect
  /// - Smooth, professional animations
  minimal,

  /// Dark mode with neon accents.
  ///
  /// Features:
  /// - Dark glass background
  /// - Cyan/magenta neon glow
  /// - Bouncy, energetic animations
  cyberpunk,

  /// Premium, expensive feel with gold accents.
  ///
  /// Features:
  /// - Frosted glass effect
  /// - Gold border highlights
  /// - Heavy, smooth animations
  luxury,

  /// Playful, bouncy design for gaming apps.
  ///
  /// Features:
  /// - High contrast colors
  /// - Maximum bounce physics
  /// - Spark active animations
  gaming,

  /// Soft, calming design for wellness apps.
  ///
  /// Features:
  /// - Muted, pastel colors
  /// - Slow, gentle animations
  /// - Subtle glass effect
  zen,

  /// Bold, modern design with sharp edges.
  ///
  /// Features:
  /// - Sharp snap animations
  /// - Square lens shape
  /// - High contrast
  modern,

  /// Retro-futuristic with warm colors.
  ///
  /// Features:
  /// - Orange/amber accents
  /// - Viscous fluid animation
  /// - Strong refraction
  retrowave,

  /// Nature-inspired with earthy tones.
  ///
  /// Features:
  /// - Green/brown colors
  /// - Soft drift animation
  /// - Organic feel
  nature,

  /// Space-themed with cosmic colors.
  ///
  /// Features:
  /// - Deep purple/blue
  /// - Zero gravity animation
  /// - Star-like shimmer
  cosmic,

  /// Professional, corporate design.
  ///
  /// Features:
  /// - Navy/gray colors
  /// - Sharp, precise animations
  /// - Minimal decorations
  corporate,
}

/// Complete theme configuration for [GlassNavBar].
///
/// Contains all styling properties needed to completely theme a navbar.
/// Use [GlassNavBarPreset] for pre-built themes or create custom ones.
class GlassNavBarThemeData {
  /// Height of the navigation bar.
  final double height;

  /// Backdrop blur intensity (sigma value).
  final double blur;

  /// Opacity of the glass tint (0.0 - 1.0).
  final double opacity;

  /// Background refraction/magnification factor.
  final double refraction;

  /// Lens refraction/magnification factor.
  final double lensRefraction;

  /// Glass tint color.
  final Color backgroundColor;

  /// Color of selected item icons and labels.
  final Color selectedItemColor;

  /// Color of unselected item icons and labels.
  final Color unselectedItemColor;

  /// Border radius of the navbar.
  final BorderRadius? borderRadius;

  /// Width of the selection lens.
  final double? lensWidth;

  /// Height of the selection lens.
  final double? lensHeight;

  /// Border radius of the lens.
  final BorderRadius? lensBorderRadius;

  /// Glow/border color of the lens.
  final Color? lensBorderColor;

  /// Static blur on the lens.
  final double lensBlur;

  /// Lens shine/glow intensity.
  final double glassiness;

  /// Bar border shine intensity.
  final double barGlassiness;

  /// Whether to show text labels.
  final bool showLabels;

  /// Animation physics preset.
  final GlassAnimation animationEffect;

  /// Custom spring physics (overrides [animationEffect]).
  final SpringDescription? animationPhysics;

  /// Icon animation when selected.
  final GlassActiveItemAnimation activeItemAnimation;

  /// Outer margin around the navbar.
  final EdgeInsets? margin;

  /// Inner padding for navbar content.
  final EdgeInsets? barPadding;

  /// Size of item icons.
  final double itemIconSize;

  /// Text style for item labels.
  final TextStyle itemTextStyle;

  /// Motion blur strength when lens moves.
  final double lensMotionBlurStrength;

  /// Border light source angle (radians).
  final double borderLightSource;

  const GlassNavBarThemeData({
    this.height = 70,
    this.blur = 5,
    this.opacity = 0.08,
    this.refraction = 1.25,
    this.lensRefraction = 1.5,
    this.backgroundColor = Colors.black,
    this.selectedItemColor = Colors.white,
    this.unselectedItemColor = Colors.white54,
    this.borderRadius,
    this.lensWidth,
    this.lensHeight,
    this.lensBorderRadius,
    this.lensBorderColor,
    this.lensBlur = 0.0,
    this.glassiness = 1.0,
    this.barGlassiness = 1.0,
    this.showLabels = false,
    this.animationEffect = GlassAnimation.elasticRubber,
    this.animationPhysics,
    this.activeItemAnimation = GlassActiveItemAnimation.zoom,
    this.margin,
    this.barPadding,
    this.itemIconSize = 24,
    this.itemTextStyle =
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    this.lensMotionBlurStrength = 15.0,
    this.borderLightSource = 0.785,
  });

  /// Creates a copy with modified properties.
  GlassNavBarThemeData copyWith({
    double? height,
    double? blur,
    double? opacity,
    double? refraction,
    double? lensRefraction,
    Color? backgroundColor,
    Color? selectedItemColor,
    Color? unselectedItemColor,
    BorderRadius? borderRadius,
    double? lensWidth,
    double? lensHeight,
    BorderRadius? lensBorderRadius,
    Color? lensBorderColor,
    double? lensBlur,
    double? glassiness,
    double? barGlassiness,
    bool? showLabels,
    GlassAnimation? animationEffect,
    SpringDescription? animationPhysics,
    GlassActiveItemAnimation? activeItemAnimation,
    EdgeInsets? margin,
    EdgeInsets? barPadding,
    double? itemIconSize,
    TextStyle? itemTextStyle,
    double? lensMotionBlurStrength,
    double? borderLightSource,
  }) {
    return GlassNavBarThemeData(
      height: height ?? this.height,
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      refraction: refraction ?? this.refraction,
      lensRefraction: lensRefraction ?? this.lensRefraction,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedItemColor: selectedItemColor ?? this.selectedItemColor,
      unselectedItemColor: unselectedItemColor ?? this.unselectedItemColor,
      borderRadius: borderRadius ?? this.borderRadius,
      lensWidth: lensWidth ?? this.lensWidth,
      lensHeight: lensHeight ?? this.lensHeight,
      lensBorderRadius: lensBorderRadius ?? this.lensBorderRadius,
      lensBorderColor: lensBorderColor ?? this.lensBorderColor,
      lensBlur: lensBlur ?? this.lensBlur,
      glassiness: glassiness ?? this.glassiness,
      barGlassiness: barGlassiness ?? this.barGlassiness,
      showLabels: showLabels ?? this.showLabels,
      animationEffect: animationEffect ?? this.animationEffect,
      animationPhysics: animationPhysics ?? this.animationPhysics,
      activeItemAnimation: activeItemAnimation ?? this.activeItemAnimation,
      margin: margin ?? this.margin,
      barPadding: barPadding ?? this.barPadding,
      itemIconSize: itemIconSize ?? this.itemIconSize,
      itemTextStyle: itemTextStyle ?? this.itemTextStyle,
      lensMotionBlurStrength:
          lensMotionBlurStrength ?? this.lensMotionBlurStrength,
      borderLightSource: borderLightSource ?? this.borderLightSource,
    );
  }
}

/// Extension to get theme data from presets.
extension GlassNavBarPresetExtension on GlassNavBarPreset {
  /// Returns the complete theme configuration for this preset.
  GlassNavBarThemeData get theme {
    switch (this) {
      case GlassNavBarPreset.minimal:
        return const GlassNavBarThemeData(
          height: 65,
          blur: 8,
          opacity: 0.1,
          refraction: 1.1,
          lensRefraction: 1.15,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black38,
          glassiness: 0.5,
          barGlassiness: 0.5,
          animationEffect: GlassAnimation.heavyGlass,
          activeItemAnimation: GlassActiveItemAnimation.zoom,
          lensMotionBlurStrength: 5,
        );

      case GlassNavBarPreset.cyberpunk:
        return GlassNavBarThemeData(
          height: 75,
          blur: 20,
          opacity: 0.15,
          refraction: 1.3,
          lensRefraction: 1.5,
          backgroundColor: Colors.black,
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.white30,
          lensBorderColor: Colors.cyanAccent.withAlpha2(0.6),
          glassiness: 1.5,
          barGlassiness: 1.2,
          animationEffect: GlassAnimation.bouncyWater,
          activeItemAnimation: GlassActiveItemAnimation.spark,
          lensMotionBlurStrength: 20,
        );

      case GlassNavBarPreset.luxury:
        return GlassNavBarThemeData(
          height: 80,
          blur: 10,
          opacity: 0.08,
          refraction: 1.15,
          lensRefraction: 1.2,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFD4AF37), // Gold
          unselectedItemColor: Colors.grey.shade400,
          lensWidth: 70,
          lensBorderRadius: BorderRadius.circular(16),
          lensBorderColor: const Color(0xFFC5A000),
          lensBlur: 5,
          glassiness: 1.3,
          barGlassiness: 1.0,
          showLabels: true,
          animationEffect: GlassAnimation.heavyGlass,
          animationPhysics:
              const SpringDescription(mass: 1.5, stiffness: 70, damping: 18),
          activeItemAnimation: GlassActiveItemAnimation.shimmer,
          lensMotionBlurStrength: 8,
        );

      case GlassNavBarPreset.gaming:
        return GlassNavBarThemeData(
          height: 70,
          blur: 15,
          opacity: 0.12,
          refraction: 1.25,
          lensRefraction: 1.4,
          backgroundColor: const Color(0xFF0D0D15),
          selectedItemColor: Colors.purpleAccent,
          unselectedItemColor: Colors.white24,
          lensBorderColor: Colors.purpleAccent.withAlpha2(0.5),
          glassiness: 1.8,
          barGlassiness: 1.3,
          animationEffect: GlassAnimation.wobblyJelly,
          activeItemAnimation: GlassActiveItemAnimation.spark,
          lensMotionBlurStrength: 25,
        );

      case GlassNavBarPreset.zen:
        return GlassNavBarThemeData(
          height: 60,
          blur: 5,
          opacity: 0.06,
          refraction: 1.1,
          lensRefraction: 1.15,
          backgroundColor: const Color(0xFFF5F5F0),
          selectedItemColor: const Color(0xFF5D5C5C),
          unselectedItemColor: const Color(0xFFB0B0A8),
          glassiness: 0.3,
          barGlassiness: 0.3,
          animationEffect: GlassAnimation.lazyHoney,
          activeItemAnimation: GlassActiveItemAnimation.none,
          lensMotionBlurStrength: 3,
        );

      case GlassNavBarPreset.modern:
        return GlassNavBarThemeData(
          height: 65,
          blur: 12,
          opacity: 0.1,
          refraction: 1.2,
          lensRefraction: 1.3,
          backgroundColor: Colors.black87,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white38,
          borderRadius: BorderRadius.circular(16),
          lensBorderRadius: BorderRadius.circular(12),
          glassiness: 1.0,
          barGlassiness: 0.8,
          animationEffect: GlassAnimation.sharpSnap,
          activeItemAnimation: GlassActiveItemAnimation.zoom,
          lensMotionBlurStrength: 10,
        );

      case GlassNavBarPreset.retrowave:
        return GlassNavBarThemeData(
          height: 75,
          blur: 18,
          opacity: 0.15,
          refraction: 1.35,
          lensRefraction: 1.5,
          backgroundColor: const Color(0xFF1A0A2E),
          selectedItemColor: const Color(0xFFFF6B35),
          unselectedItemColor: const Color(0xFF8B5CF6).withAlpha2(0.5),
          lensBorderColor: const Color(0xFFFF6B35).withAlpha2(0.4),
          glassiness: 1.4,
          barGlassiness: 1.2,
          animationEffect: GlassAnimation.viscousFluid,
          activeItemAnimation: GlassActiveItemAnimation.shimmer,
          lensMotionBlurStrength: 18,
        );

      case GlassNavBarPreset.nature:
        return GlassNavBarThemeData(
          height: 65,
          blur: 8,
          opacity: 0.08,
          refraction: 1.15,
          lensRefraction: 1.2,
          backgroundColor: const Color(0xFFF0EDE5),
          selectedItemColor: const Color(0xFF2D5A27),
          unselectedItemColor: const Color(0xFF8B7355).withAlpha2(0.6),
          glassiness: 0.6,
          barGlassiness: 0.5,
          animationEffect: GlassAnimation.softDrift,
          activeItemAnimation: GlassActiveItemAnimation.zoom,
          lensMotionBlurStrength: 5,
        );

      case GlassNavBarPreset.cosmic:
        return GlassNavBarThemeData(
          height: 70,
          blur: 25,
          opacity: 0.1,
          refraction: 1.3,
          lensRefraction: 1.45,
          backgroundColor: const Color(0xFF0B0B1A),
          selectedItemColor: const Color(0xFFE0AAFF),
          unselectedItemColor: const Color(0xFF7B68EE).withAlpha2(0.4),
          lensBorderColor: const Color(0xFFE0AAFF).withAlpha2(0.3),
          glassiness: 1.6,
          barGlassiness: 1.4,
          animationEffect: GlassAnimation.zeroGravity,
          activeItemAnimation: GlassActiveItemAnimation.shimmer,
          lensMotionBlurStrength: 12,
        );

      case GlassNavBarPreset.corporate:
        return const GlassNavBarThemeData(
          height: 60,
          blur: 6,
          opacity: 0.08,
          refraction: 1.1,
          lensRefraction: 1.15,
          backgroundColor: Color(0xFF1E3A5F),
          selectedItemColor: Colors.white,
          unselectedItemColor: Color(0xFF7A9CC6),
          glassiness: 0.7,
          barGlassiness: 0.6,
          animationEffect: GlassAnimation.sharpSnap,
          activeItemAnimation: GlassActiveItemAnimation.none,
          lensMotionBlurStrength: 5,
        );
    }
  }
}
