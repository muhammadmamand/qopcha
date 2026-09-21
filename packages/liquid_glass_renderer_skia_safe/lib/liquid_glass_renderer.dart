import 'dart:ui';

import 'package:flutter/material.dart';

class LiquidGlassSettings {
  const LiquidGlassSettings({
    this.visibility = 1.0,
    this.glassColor = const Color.fromARGB(0, 255, 255, 255),
    this.thickness = 20,
    this.blur = 5,
    this.chromaticAberration = .01,
    this.lightAngle = 1.5707963267948966,
    this.lightIntensity = .5,
    this.ambientStrength = 0,
    this.refractiveIndex = 1.2,
    this.saturation = 1.5,
  });

  final double visibility;
  final Color glassColor;
  final double thickness;
  final double blur;
  final double chromaticAberration;
  final double lightAngle;
  final double lightIntensity;
  final double ambientStrength;
  final double refractiveIndex;
  final double saturation;

  Color get effectiveGlassColor =>
      glassColor.withValues(alpha: glassColor.a * visibility);

  double get effectiveBlur => blur * visibility;

  LiquidGlassSettings copyWith({
    double? visibility,
    Color? glassColor,
    double? thickness,
    double? blur,
    double? chromaticAberration,
    double? lightAngle,
    double? lightIntensity,
    double? ambientStrength,
    double? refractiveIndex,
    double? saturation,
  }) {
    return LiquidGlassSettings(
      visibility: visibility ?? this.visibility,
      glassColor: glassColor ?? this.glassColor,
      thickness: thickness ?? this.thickness,
      blur: blur ?? this.blur,
      chromaticAberration: chromaticAberration ?? this.chromaticAberration,
      lightAngle: lightAngle ?? this.lightAngle,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      ambientStrength: ambientStrength ?? this.ambientStrength,
      refractiveIndex: refractiveIndex ?? this.refractiveIndex,
      saturation: saturation ?? this.saturation,
    );
  }
}

abstract class LiquidShape {
  Path getPath(Rect rect);
  BorderRadius get clipRadius;
}

class LiquidRoundedSuperellipse implements LiquidShape {
  const LiquidRoundedSuperellipse({required this.borderRadius});

  final double borderRadius;

  @override
  BorderRadius get clipRadius => BorderRadius.circular(borderRadius);

  @override
  Path getPath(Rect rect) {
    return Path()..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
        );
  }
}

class LiquidRoundedRectangle implements LiquidShape {
  const LiquidRoundedRectangle({required this.borderRadius});

  final double borderRadius;

  @override
  BorderRadius get clipRadius => BorderRadius.circular(borderRadius);

  @override
  Path getPath(Rect rect) {
    return Path()..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
        );
  }
}

class LiquidOval implements LiquidShape {
  const LiquidOval();

  @override
  BorderRadius get clipRadius => BorderRadius.circular(9999);

  @override
  Path getPath(Rect rect) => Path()..addOval(rect);
}

class _LayerScope extends InheritedWidget {
  const _LayerScope({
    required this.settings,
    required this.fake,
    required super.child,
  });

  final LiquidGlassSettings settings;
  final bool fake;

  static _LayerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LayerScope>();
  }

  @override
  bool updateShouldNotify(_LayerScope oldWidget) {
    return settings != oldWidget.settings || fake != oldWidget.fake;
  }
}

class _BlendGroupScope extends InheritedWidget {
  const _BlendGroupScope({
    required this.blend,
    required super.child,
  });

  final double blend;

  static _BlendGroupScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_BlendGroupScope>();
  }

  @override
  bool updateShouldNotify(_BlendGroupScope oldWidget) => blend != oldWidget.blend;
}

class LiquidGlassLayer extends StatelessWidget {
  const LiquidGlassLayer({
    required this.child,
    this.settings = const LiquidGlassSettings(),
    this.fake = false,
    super.key,
  });

  final Widget child;
  final LiquidGlassSettings settings;
  final bool fake;

  @override
  Widget build(BuildContext context) {
    return _LayerScope(
      settings: settings,
      fake: fake,
      child: child,
    );
  }
}

class LiquidGlassBlendGroup extends StatelessWidget {
  const LiquidGlassBlendGroup({
    required this.child,
    this.blend = 20,
    super.key,
  });

  final Widget child;
  final double blend;

  @override
  Widget build(BuildContext context) {
    final layer = _LayerScope.maybeOf(context);
    final settings = layer?.settings ?? const LiquidGlassSettings();
    final sigma = settings.effectiveBlur.clamp(0.0, 30.0);

    return _BlendGroupScope(
      blend: blend,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: child,
        ),
      ),
    );
  }
}

class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    required this.child,
    required this.shape,
    this.clipBehavior = Clip.hardEdge,
    super.key,
  })  : grouped = false,
        _settings = null;

  const LiquidGlass.grouped({
    required this.child,
    required this.shape,
    this.clipBehavior = Clip.hardEdge,
    super.key,
  })  : grouped = true,
        _settings = null;

  const LiquidGlass.withOwnLayer({
    required this.child,
    required this.shape,
    LiquidGlassSettings settings = const LiquidGlassSettings(),
    this.clipBehavior = Clip.hardEdge,
    super.key,
  })  : grouped = false,
        _settings = settings;

  final Widget child;
  final LiquidShape shape;
  final bool grouped;
  final Clip clipBehavior;
  final LiquidGlassSettings? _settings;

  @override
  Widget build(BuildContext context) {
    final layer = _LayerScope.maybeOf(context);
    final blendGroup = _BlendGroupScope.maybeOf(context);
    final settings =
        _settings ?? layer?.settings ?? const LiquidGlassSettings();
    final radius = shape.clipRadius;

    if (grouped && blendGroup != null) {
      return ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: settings.effectiveGlassColor,
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.42 * settings.visibility),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      );
    }

    return FakeGlass(shape: shape, settings: settings, child: child);
  }
}

class FakeGlass extends StatelessWidget {
  const FakeGlass({
    required this.shape,
    required this.child,
    this.settings = const LiquidGlassSettings(),
    super.key,
  });

  final LiquidShape shape;
  final Widget child;
  final LiquidGlassSettings settings;

  @override
  Widget build(BuildContext context) {
    final radius = shape.clipRadius;
    final sigma = settings.effectiveBlur.clamp(0.0, 30.0);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: settings.effectiveGlassColor,
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45 * settings.visibility),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassGlow extends StatelessWidget {
  const GlassGlow({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class GlassGlowLayer extends StatelessWidget {
  const GlassGlowLayer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
