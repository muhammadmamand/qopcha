import 'package:flutter/physics.dart';

/// Pre-defined fluid animation physics for the [GlassNavBar] lens.
enum GlassAnimation {
  /// Low stiffness, low damping. Feels like zero-gravity or air hockey.
  softDrift,

  /// High stiffness, low damping. Very bouncy and elastic.
  bouncyWater,

  /// High mass, high damping. Feels smooth, expensive, and heavy.
  heavyGlass,

  /// High stiffness, critical damping. Snaps instantly with no overshoot.
  sharpSnap,

  /// Low stiffness, high damping. Moves slowly like viscous liquid.
  lazyHoney,

  /// Balanced stiffness and damping. Standard rubber-band feel.
  elasticRubber,

  viscousFluid,
  magneticLock,
  zeroGravity,
  hyperQuantum,
  wobblyJelly,
  heavyMetal,
  slowMotion,
  furiousSpring,
  glassCannon,
  pillowySoft,
  orbitalDrift,
}

/// Defines the animation effect when the lens is active over an item.
enum GlassActiveItemAnimation {
  /// The icon scales up smoothly (Default).
  /// The icon scales up smoothly (Default).
  zoom,

  /// A white shimmer gradient passes over the icon.
  shimmer,

  /// The icon flashes consistently.
  spark,

  /// No animation, just static color change.
  none,
}

/// Configuration for physics and shape deformation.
class GlassAnimationConfig {
  final SpringDescription physics;
  final double stretchFactor; // 0.0 = none, >0 = stretch, <0 = compress
  final double radiusMorph; // Change in corner radius per velocity unit
  final bool wobble; // Enable sine-wave distortion

  const GlassAnimationConfig({
    required this.physics,
    this.stretchFactor = 0.0,
    this.radiusMorph = 0.0,
    this.wobble = false,
  });
}

/// Helper to get configuration for a given [GlassAnimation].
GlassAnimationConfig getGlassAnimationConfig(GlassAnimation animation) {
  switch (animation) {
    // --- 1. Viscous Fluid (Thick, oily, stretchy) ---
    case GlassAnimation.viscousFluid:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 1.8, stiffness: 55.0, damping: 28.0),
        stretchFactor: 0.42,
        radiusMorph: 6.0,
      );

    // --- 2. Magnetic Lock (Snappy, thins out, square snap) ---
    case GlassAnimation.magneticLock:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 0.2, stiffness: 400.0, damping: 20.0),
        stretchFactor: -0.1, // Thins out
        radiusMorph: -20.0, // Becomes square on move
      );

    // --- 3. Zero Gravity (Floaty, drifting) ---
    case GlassAnimation.zeroGravity:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 0.1, stiffness: 5.0, damping: 0.5),
        stretchFactor: 0.0,
      );

    // --- 4. Hyper Quantum (Jittery teleportation) ---
    case GlassAnimation.hyperQuantum:
      return const GlassAnimationConfig(
        physics:
            SpringDescription(mass: 0.05, stiffness: 900.0, damping: 100.0),
        wobble: true,
      );

    // --- 5. Wobbly Jelly (Massive wobble) ---
    case GlassAnimation.wobblyJelly:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 1.0, stiffness: 80.0, damping: 2.0),
        stretchFactor: 0.5,
        wobble: true,
      );

    // --- 6. Heavy Metal (Rigid, heavy momentum) ---
    case GlassAnimation.heavyMetal:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 4.0, stiffness: 300.0, damping: 30.0),
        stretchFactor: 0.0, // Rigid
      );

    // --- 7. Slow Motion (Movie-like) ---
    case GlassAnimation.slowMotion:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 1.0, stiffness: 10.0, damping: 10.0),
        stretchFactor: 0.1,
      );

    // --- 8. Furious Spring (High energy, pulsing radius) ---
    case GlassAnimation.furiousSpring:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 2.0, stiffness: 500.0, damping: 5.0),
        radiusMorph: 15.0, // Becomes rounder or changes shape
      );

    // --- 9. Glass Cannon (Fast launch, hard impact) ---
    case GlassAnimation.glassCannon:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 0.5, stiffness: 200.0, damping: 40.0),
        stretchFactor: -0.15, // Compresses
      );

    // --- 10. Pillowy Soft (Soft landing, spreads) ---
    case GlassAnimation.pillowySoft:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 0.8, stiffness: 40.0, damping: 12.0),
        stretchFactor: 0.2, // Spreads out
      );

    // --- 11. Orbital Drift (Massive drift) ---
    case GlassAnimation.orbitalDrift:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 3.0, stiffness: 20.0, damping: 5.0),
        stretchFactor: 0.05,
      );

    // --- Existing Presets mapped to new config ---
    case GlassAnimation.softDrift:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 0.1, stiffness: 20.0, damping: 2.0),
      );
    case GlassAnimation.bouncyWater:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 0.8, stiffness: 150.0, damping: 10.0),
        stretchFactor: 0.2,
      );
    case GlassAnimation.heavyGlass:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 1.0, stiffness: 60.0, damping: 12.0),
      );
    case GlassAnimation.sharpSnap:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 1.0, stiffness: 300.0, damping: 35.0),
        stretchFactor: -0.05,
      );
    case GlassAnimation.lazyHoney:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 2.0, stiffness: 30.0, damping: 30.0),
        stretchFactor: 0.1,
      );
    case GlassAnimation.elasticRubber:
      return const GlassAnimationConfig(
        physics: SpringDescription(mass: 1.0, stiffness: 100.0, damping: 15.0),
        stretchFactor: 0.1,
      );
  }
}
