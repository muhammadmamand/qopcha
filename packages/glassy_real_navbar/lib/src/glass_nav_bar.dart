import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'glass_container.dart';
import 'glass_nav_item.dart';
import 'glass_animation.dart';
import 'glass_theme.dart';
import 'dart:math' as math;

/// Helper extension to use withValues instead of deprecated withOpacity
extension _ColorAlpha on Color {
  Color withAlpha2(double opacity) =>
      withValues(alpha: opacity.clamp(0.0, 1.0));
}

/// A beautiful glassmorphism navigation bar with liquid lens effect.
///
/// [GlassNavBar] provides a modern, iOS 26-style navigation experience with
/// realistic glass physics, smooth animations, and extensive customization.
///
/// ## Basic Usage
///
/// ```dart
/// GlassNavBar(
///   selectedIndex: _index,
///   onItemSelected: (i) => setState(() => _index = i),
///   items: [
///     GlassNavBarItem(icon: Icons.home, title: 'Home'),
///     GlassNavBarItem(icon: Icons.search, title: 'Search'),
///     GlassNavBarItem(icon: Icons.person, title: 'Profile'),
///   ],
/// )
/// ```
///
/// ## Using Presets
///
/// ```dart
/// GlassNavBar.preset(
///   preset: GlassNavBarPreset.cyberpunk,
///   selectedIndex: _index,
///   onItemSelected: (i) => setState(() => _index = i),
///   items: [...],
/// )
/// ```
///
/// See also:
/// - [GlassNavBarItem] for navigation items
/// - [GlassNavBarPreset] for pre-built themes
/// - [GlassAnimation] for physics presets
class GlassNavBar extends StatefulWidget {
  /// The navigation items to display.
  final List<GlassNavBarItem> items;

  /// The index of the currently selected item.
  final int selectedIndex;

  /// Called when an item is selected.
  final ValueChanged<int> onItemSelected;

  /// Height of the navigation bar.
  final double height;

  /// Backdrop blur intensity (sigma value).
  final double blur;

  /// Opacity of the glass tint (0.0 - 1.0).
  final double opacity;

  /// Glass tint color.
  final Color backgroundColor;

  /// Color of selected item icons and labels.
  final Color selectedItemColor;

  /// Color of unselected item icons and labels.
  final Color unselectedItemColor;

  /// Opacity of the lens container.
  final double lensOpacity;

  /// Whether to show text labels below icons.
  final bool showLabels;

  /// Background refraction/magnification factor (1.0 = none).
  final double refraction;

  /// Lens refraction/magnification factor (1.0 = none).
  final double lensRefraction;

  /// Border radius of the navigation bar.
  final BorderRadius? borderRadius;

  /// Creates a glass navigation bar.
  ///
  /// The [items], [selectedIndex], and [onItemSelected] parameters are required.
  const GlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.height = 70,
    this.blur = 5,
    this.opacity = 0.08,
    this.refraction = 1.25,
    this.lensRefraction = 1.50,
    this.backgroundColor = Colors.black,
    this.selectedItemColor = Colors.white,
    this.unselectedItemColor = Colors.white54,
    this.lensOpacity = 0.1,
    this.showLabels = false,
    this.borderRadius,
    this.lensWidth,
    this.lensHeight,
    this.lensBorderRadius,
    this.lensBorderColor,
    this.lensBlur = 0.0,
    this.glassiness = 1.0,
    this.lensVelocityRefraction = 0.05,
    this.barPadding,
    this.margin,
    this.itemSpacing,
    this.animationEffect = GlassAnimation.elasticRubber,
    this.animationPhysics,
    this.activeItemAnimation = GlassActiveItemAnimation.zoom,
    this.barGlassiness = 1.0,
    this.lensMotionBlurStrength = 15.0,
    this.borderLightSource = 0.785,
    this.itemIconSize = 24.0,
    this.itemTextStyle =
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  });

  /// Creates a glass navigation bar from a preset theme.
  ///
  /// This factory constructor makes it easy to apply pre-built themes:
  ///
  /// ```dart
  /// GlassNavBar.preset(
  ///   preset: GlassNavBarPreset.cyberpunk,
  ///   selectedIndex: _index,
  ///   onItemSelected: (i) => setState(() => _index = i),
  ///   items: [
  ///     GlassNavBarItem(icon: Icons.home, title: 'Home'),
  ///     GlassNavBarItem(icon: Icons.search, title: 'Search'),
  ///   ],
  /// )
  /// ```
  factory GlassNavBar.preset({
    Key? key,
    required GlassNavBarPreset preset,
    required List<GlassNavBarItem> items,
    required int selectedIndex,
    required ValueChanged<int> onItemSelected,
    // Allow overriding specific properties
    double? height,
    double? blur,
    double? opacity,
    Color? backgroundColor,
    Color? selectedItemColor,
    Color? unselectedItemColor,
    bool? showLabels,
    BorderRadius? borderRadius,
    EdgeInsets? margin,
    GlassAnimation? animationEffect,
  }) {
    final theme = preset.theme;
    return GlassNavBar(
      key: key,
      items: items,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      height: height ?? theme.height,
      blur: blur ?? theme.blur,
      opacity: opacity ?? theme.opacity,
      refraction: theme.refraction,
      lensRefraction: theme.lensRefraction,
      backgroundColor: backgroundColor ?? theme.backgroundColor,
      selectedItemColor: selectedItemColor ?? theme.selectedItemColor,
      unselectedItemColor: unselectedItemColor ?? theme.unselectedItemColor,
      showLabels: showLabels ?? theme.showLabels,
      borderRadius: borderRadius ?? theme.borderRadius,
      lensWidth: theme.lensWidth,
      lensHeight: theme.lensHeight,
      lensBorderRadius: theme.lensBorderRadius,
      lensBorderColor: theme.lensBorderColor,
      lensBlur: theme.lensBlur,
      glassiness: theme.glassiness,
      barGlassiness: theme.barGlassiness,
      animationEffect: animationEffect ?? theme.animationEffect,
      animationPhysics: theme.animationPhysics,
      activeItemAnimation: theme.activeItemAnimation,
      margin: margin ?? theme.margin,
      barPadding: theme.barPadding,
      itemIconSize: theme.itemIconSize,
      itemTextStyle: theme.itemTextStyle,
      lensMotionBlurStrength: theme.lensMotionBlurStrength,
      borderLightSource: theme.borderLightSource,
    );
  }

  /// Width of the selection lens (null = auto-calculated).
  final double? lensWidth;

  /// Height of the selection lens (null = matches bar height).
  final double? lensHeight;

  /// Border radius of the lens.
  final BorderRadius? lensBorderRadius;

  /// Glow/border color of the lens.
  final Color? lensBorderColor;

  /// Static blur applied to the lens.
  final double lensBlur;

  /// Lens shine/glow intensity multiplier.
  final double glassiness;

  /// Extra refraction added based on velocity.
  final double lensVelocityRefraction;

  /// Inner padding for navbar content.
  final EdgeInsets? barPadding;

  /// Outer margin around the navbar.
  final EdgeInsets? margin;

  /// Custom spacing between items (null = spaceEvenly).
  final double? itemSpacing;

  /// Physics preset for lens animation.
  final GlassAnimation animationEffect;

  /// Custom spring physics (overrides [animationEffect]).
  final SpringDescription? animationPhysics;

  /// Animation effect when item is selected.
  final GlassActiveItemAnimation activeItemAnimation;

  /// Bar border shine intensity.
  final double barGlassiness;

  /// Motion blur strength when lens moves.
  final double lensMotionBlurStrength;

  /// Border light source angle (radians).
  final double borderLightSource;

  /// Size of item icons.
  final double itemIconSize;

  /// Text style for item labels.
  final TextStyle itemTextStyle;

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // We don't strictly use a Tween anymore because we need physics simulations

  // Track alignment [-1.0, 1.0]
  double _currentAlignment = 0.0;

  // To measure the width for accurate drag calculations
  final GlobalKey _barKey = GlobalKey();

  // Cache the global position of the bar for accurate refraction anchoring
  Offset? _barGlobalPosition;

  @override
  void initState() {
    super.initState();
    _currentAlignment = _getAlignment(widget.selectedIndex);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: -1.0, // Allow full range for alignment
      upperBound: 1.0,
    )..addListener(() {
        setState(() {
          _currentAlignment = _controller.value;
        });
      });

    // Set initial value
    _controller.value = _currentAlignment;

    // Attempt to get position after first frame
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateGlobalPosition());
  }

  void _updateGlobalPosition() {
    final RenderBox? box =
        _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && mounted) {
      final Offset position = box.localToGlobal(Offset.zero);
      if (_barGlobalPosition != position) {
        setState(() {
          _barGlobalPosition = position;
        });
      }
    }
  }

  @override
  void didUpdateWidget(GlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        !_controller.isAnimating) {
      _animateTo(widget.selectedIndex);
    }
  }

  void _animateTo(int index) {
    _updateGlobalPosition();
    final double targetAlign = _getAlignment(index);

    // Tuned for "Heavy Glass" feel
    // Lower stiffness = heavier object
    // Damping optimized for a fluid stop without excessive oscillation
    final GlassAnimationConfig config =
        getGlassAnimationConfig(widget.animationEffect);
    final SpringDescription spring = widget.animationPhysics ?? config.physics;

    final SpringSimulation simulation = SpringSimulation(
        spring, _currentAlignment, targetAlign, 0.0 // Initial velocity
        );

    _controller.animateWith(simulation);
  }

  double _getAlignment(int index) {
    if (widget.items.isEmpty) return 0.0;
    return (index / (widget.items.length - 1)) * 2.0 - 1.0;
  }

  void _handleDragStart(DragStartDetails details) {
    _updateGlobalPosition();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final RenderBox? box =
        _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final double width = box.size.width;
      // Convert pixel delta to alignment delta (range 2.0)
      final double deltaAlign = (details.delta.dx / width) * 2.0;

      setState(() {
        _currentAlignment += deltaAlign;
        // Clamp to avoid dragging off edge
        _currentAlignment = _currentAlignment.clamp(-1.0, 1.0);
        _controller.value = _currentAlignment; // Keep controller in sync
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    // Find nearest index
    int nearestIndex = 0;
    double minDiff = double.infinity;

    for (int i = 0; i < widget.items.length; i++) {
      final double align = _getAlignment(i);
      final double diff = (_currentAlignment - align).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearestIndex = i;
      }
    }

    // Notify selection
    if (nearestIndex != widget.selectedIndex) {
      widget.onItemSelected(nearestIndex);
    }

    // Snap to it
    _animateTo(nearestIndex);
  }

  void _handleTapUp(TapUpDetails details) {
    _updateGlobalPosition();
    final RenderBox? box =
        _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final double width = box.size.width;
      final double itemWidth = width / widget.items.length;
      final int index = (details.localPosition.dx / itemWidth).floor();

      if (index >= 0 && index < widget.items.length) {
        widget.onItemSelected(index);
        _animateTo(index); // Explicitly animate to valid index
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate Velocity for Motion Effects
    double velocity = 0.0;
    if (_controller.isAnimating) {
      velocity = _controller.velocity.abs();
    }

    // 1. Get Config
    final GlassAnimationConfig config =
        getGlassAnimationConfig(widget.animationEffect);

    // 2. Squash & Stretch based on Config
    double stretch = (velocity * config.stretchFactor).clamp(-0.5, 0.5);

    // 3. Wobble Effect (If enabled)
    if (config.wobble && velocity > 0.1) {
      // Oscillate stretch based on velocity to simulate jelly-wobble
      stretch += math.sin(velocity * 10) * 0.2;
    }

    final double widthMultiplier = 1.0 + stretch;
    final double heightMultiplier = 1.0 - (stretch * 0.5);

    // 2. Motion Blur (Clear base)
    final double motionBlur =
        (velocity * widget.lensMotionBlurStrength).clamp(0.0, 20.0);
    // Combine with base blur
    final double totalLensBlur = widget.lensBlur + motionBlur;

    // Determine shape
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(widget.height / 2);
    // Determine lens shape
    // Determine lens shape with Radius Morph
    BorderRadius effectiveLensRadius =
        widget.lensBorderRadius ?? BorderRadius.circular(widget.height / 2);

    if (config.radiusMorph != 0.0) {
      // Morph radius based on velocity
      // Reduce radius = more square, Increase = more round (if starting square)
      // Since default is round, usually we morph to square (negative).
      double deltaRadius = velocity * config.radiusMorph;

      // We need to know the base radius value to modify it.
      // Assuming uniform radius for simplicity or taking topLeft.
      double baseRadius = effectiveLensRadius.topLeft.x;
      double newRadius = (baseRadius + deltaRadius).clamp(0.0, 100.0);
      effectiveLensRadius = BorderRadius.circular(newRadius);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double barWidth = constraints.maxWidth;
        // Use custom lens width or default to equal distribution
        final double baseLensWidth =
            widget.lensWidth ?? (barWidth / widget.items.length);
        final double lensWidth = baseLensWidth * widthMultiplier;

        // Calculate Focal Points
        Offset? lensFocalPoint;
        Offset? barFocalPoint;

        if (_barGlobalPosition != null) {
          final double barHeight = widget.height;

          barFocalPoint =
              _barGlobalPosition! + Offset(barWidth / 2, barHeight / 2);

          // Calculate lens center to match spaceEvenly positioning
          final double normalizedAlign =
              (_currentAlignment + 1.0) / 2.0; // 0.0 to 1.0
          final int itemCount = widget.items.length;
          final double targetIndex = normalizedAlign * (itemCount - 1);
          // spaceEvenly center position for this index
          final double centerX = (targetIndex + 0.5) / itemCount * barWidth;
          final double centerY = barHeight / 2;

          lensFocalPoint = _barGlobalPosition! + Offset(centerX, centerY);
        }

        return Container(
          margin: widget.margin,
          height: widget.height,
          child: Stack(
            children: [
              // 1. Static Glass Background
              Positioned.fill(
                child: GlassContainer(
                  key: _barKey,
                  height: widget.height,
                  blur: widget.blur,
                  opacity: widget.opacity,
                  refraction: widget.refraction,
                  focalPoint: barFocalPoint,
                  color: widget.backgroundColor,
                  borderRadius: effectiveBorderRadius, // Use dynamic shape
                  width: double.infinity,
                  glassiness: widget.barGlassiness,
                  borderLightSource: widget.borderLightSource,
                  child: null,
                ),
              ),

              // 2. Dynamic Interactive Layer
              GestureDetector(
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                onTapUp: _handleTapUp,
                behavior: HitTestBehavior.opaque,
                child: Stack(children: [
                  // 1. Tab Items (Now BEHIND the Lens for Refraction)
                  Padding(
                    padding: widget.barPadding ?? EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: widget.itemSpacing != null
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.itemSpacing != null) ...[
                          SizedBox(width: widget.itemSpacing! / 2),
                          ...widget.items.asMap().entries.expand((entry) {
                            final widgetItem =
                                _buildNavItem(entry.key, entry.value, barWidth);
                            if (entry.key < widget.items.length - 1) {
                              return [
                                widgetItem,
                                SizedBox(width: widget.itemSpacing)
                              ];
                            }
                            return [widgetItem];
                          }),
                          SizedBox(width: widget.itemSpacing! / 2),
                        ] else ...[
                          ...widget.items.asMap().entries.map(
                              (e) => _buildNavItem(e.key, e.value, barWidth)),
                        ],
                      ],
                    ),
                  ),

                  // 2. The Moving Lens (Overlay)
                  Builder(
                    builder: (context) {
                      final double normalizedAlign =
                          (_currentAlignment + 1.0) / 2.0;
                      final int itemCount = widget.items.length;
                      final double targetIndex =
                          normalizedAlign * (itemCount - 1);
                      // Center X calculation works for both spaceEvenly and custom spacing (assuming centered)
                      // For exact custom spacing alignment, we'd need more complex math, but this approximation holds for now
                      // as long as items are distributed symmetrically.
                      final double itemCenterX;

                      if (widget.itemSpacing != null) {
                        // Logic for Centered Spacing
                        // We assume items have a fixed width (either explicitly or derived)
                        // If lensWidth is explicit, we use that as item width approximation
                        // Otherwise we assume items would have consumed available space equally minus spacing?
                        // Actually, simplest is to assume lensWidth IS the item width anchor.
                        final double widthPerItem =
                            widget.lensWidth ?? (barWidth / itemCount);
                        final double spacing = widget.itemSpacing!;
                        final double totalContentWidth = (widthPerItem *
                                itemCount) +
                            (spacing *
                                itemCount); // space/2 starts, space betweens, space/2 end = count * spacing

                        final double startX =
                            (barWidth - totalContentWidth) / 2;

                        // Position = Start + (Half Space) + (Index * (Width + Space)) + (Half Width)
                        itemCenterX = startX +
                            (spacing / 2) +
                            (targetIndex * (widthPerItem + spacing)) +
                            (widthPerItem / 2);
                      } else {
                        // Logic for SpaceEvenly (Default)
                        // (Index + 0.5) / Count * TotalWidth
                        itemCenterX =
                            (targetIndex + 0.5) / itemCount * barWidth;
                      }

                      final double lensLeft = itemCenterX - (lensWidth / 2);

                      // Calculate vertical position
                      final double lHeight = widget.lensHeight ??
                          (widget.height * heightMultiplier);
                      final double lTop = (widget.height - lHeight) / 2;

                      return Positioned(
                        left: lensLeft.clamp(0.0, barWidth - lensWidth),
                        top: lTop,
                        child: SizedBox(
                          width: lensWidth,
                          height: lHeight,
                          child: CustomPaint(
                            painter: _SpectralLensPainter(
                              velocity: velocity,
                              borderColor: widget.lensBorderColor,
                              glassiness: widget.glassiness,
                              borderRadius: effectiveLensRadius,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: GlassContainer(
                                blur: totalLensBlur,
                                opacity: 0.0,
                                refraction: widget.lensRefraction +
                                    (velocity * widget.lensVelocityRefraction),
                                focalPoint: lensFocalPoint,
                                color: Colors.transparent,
                                borderRadius: effectiveLensRadius,
                                borderGradientOpacity: 0.0,
                                child: null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, GlassNavBarItem item, double barWidth) {
    // Gaussian Bell Curve Logic for smoother "Magnetic" feel
    final double itemAlignment = _getAlignment(index);
    final double distance = (_currentAlignment - itemAlignment).abs();

    final double sigma =
        2.0 / (widget.items.length * 2.5); // Dynamic sigma to prevents bleeding
    final double gaussian =
        math.exp(-(distance * distance) / (2 * sigma * sigma));

    final double scaleAmount = gaussian;

    // Scale Logic based on Animation Type
    double actualScale = 1.0;

    switch (widget.activeItemAnimation) {
      case GlassActiveItemAnimation.zoom:
        actualScale = 1.0 + (scaleAmount * 0.15);
        break;
      case GlassActiveItemAnimation.spark:
        // Pop effect
        actualScale = 1.0 + (scaleAmount * 0.25);
        break;
      case GlassActiveItemAnimation.shimmer:
        actualScale = 1.0 + (scaleAmount * 0.05);
        break;
      case GlassActiveItemAnimation.none:
        actualScale = 1.0;
        break;
    }

    // Suction Effect (Parallax)
    double suction = 0.0;
    if (widget.activeItemAnimation != GlassActiveItemAnimation.none &&
        distance < 1.0) {
      final double direction = (_currentAlignment - itemAlignment).sign;
      suction = direction * math.sin(distance * math.pi) * 12.0;
    }

    Widget child = Transform.translate(
      offset: Offset(suction, 0), // The "Suction" slide
      child: Container(
        alignment: Alignment.center,
        child: Transform.scale(
          scale: actualScale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // If animation is NONE, we simply interpolate color without opacity cross-fade
              if (widget.activeItemAnimation == GlassActiveItemAnimation.none)
                Icon(
                  item.icon,
                  color: Color.lerp(widget.unselectedItemColor,
                      widget.selectedItemColor, scaleAmount),
                  size: 24,
                )
              else
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Inactive
                    Opacity(
                      opacity: (1.0 - scaleAmount).clamp(0.0, 1.0),
                      child: Icon(
                        item.icon,
                        color: widget.unselectedItemColor,
                        size: widget.itemIconSize,
                      ),
                    ),
                    // Active
                    Opacity(
                      opacity: scaleAmount.clamp(0.0, 1.0),
                      child: _buildActiveIcon(item, scaleAmount),
                    ),
                  ],
                ),

              // Label Logic
              if (widget.showLabels)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    item.title,
                    style: widget.itemTextStyle.copyWith(
                      color: Color.lerp(widget.unselectedItemColor,
                          widget.selectedItemColor, scaleAmount),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // If itemSpacing is null, we assume spaceEvenly behavior which used Expanded
    if (widget.itemSpacing == null) {
      return Expanded(child: child);
    }
    return child;
  }

  Widget _buildActiveIcon(GlassNavBarItem item, double scaleAmount) {
    Widget icon = Icon(
      item.activeIcon ?? item.icon,
      color: widget.selectedItemColor,
      size: widget.itemIconSize,
    );

    if (widget.activeItemAnimation == GlassActiveItemAnimation.shimmer) {
      return ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.selectedItemColor,
              Colors.white.withAlpha2(0.8 * scaleAmount),
              widget.selectedItemColor,
            ],
            stops: const [0.0, 0.5, 1.0],
            transform: GradientRotation(scaleAmount * math.pi),
          ).createShader(bounds);
        },
        child: icon,
      );
    }

    if (widget.activeItemAnimation == GlassActiveItemAnimation.spark) {
      return Container(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
          BoxShadow(
            color: widget.selectedItemColor.withAlpha2(0.8 * scaleAmount),
            blurRadius: 15 * scaleAmount,
            spreadRadius: 2 * scaleAmount,
          )
        ]),
        child: icon,
      );
    }

    return icon;
  }
}

class _SpectralLensPainter extends CustomPainter {
  final double velocity;
  final Color? borderColor;
  final double glassiness;
  final BorderRadius? borderRadius;

  _SpectralLensPainter({
    this.velocity = 0.0,
    this.borderColor,
    this.glassiness = 1.0,
    this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Guard against non-finite or zero/negative sizes which can cause shader/paint assertions
    if (!size.isFinite || size.width <= 0 || size.height <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // Allow for padding
    final innerRect = rect.deflate(4.0);
    if (!innerRect.isFinite || innerRect.width <= 0 || innerRect.height <= 0) {
      return;
    }
    // Use custom radius or default
    final Radius defaultRadius = Radius.circular(innerRect.height / 2);
    final RRect rrect = borderRadius != null
        ? borderRadius!.toRRect(innerRect)
        : RRect.fromRectAndRadius(innerRect, defaultRadius);

    // Dynamic stroke width based on velocity (Motion lines)
    final double dynamicStroke = 3.0 + (velocity * 2.0).clamp(0.0, 6.0);

    // Clamp all opacity values to [0.0, 1.0] to avoid assertion failures
    double clampOpacity(double value) => value.clamp(0.0, 1.0);

    // 1. Fresnel / Internal Reflection (The dark/distortion ring)
    // Real thick glass has dark edges due to internal reflection
    final Paint fresnelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = dynamicStroke // Thicker when moving
      ..maskFilter = MaskFilter.blur(BlurStyle.normal,
          1.0 + (velocity * 0.5)) // Blurrier edges when moving
      // Use BlendMode.overlay so the dark/light rings modify the underlying color
      // Dark ring -> Deepens color; Light ring -> Brightens color
      ..blendMode = BlendMode.overlay
      ..shader = SweepGradient(
        colors: [
          (borderColor ?? Colors.black).withAlpha2(
              clampOpacity(0.2 * glassiness)), // Custom color or default
          Colors.white.withAlpha2(clampOpacity(0.4 * glassiness)),
          (borderColor ?? Colors.black)
              .withAlpha2(clampOpacity(0.3 * glassiness)),
          Colors.white.withAlpha2(clampOpacity(0.4 * glassiness)),
          (borderColor ?? Colors.black)
              .withAlpha2(clampOpacity(0.2 * glassiness)),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(3.14 / 4), // Diagonal light
      ).createShader(rect);

    canvas.drawRRect(rrect, fresnelPaint);
  }

  @override
  bool shouldRepaint(covariant _SpectralLensPainter oldDelegate) {
    return oldDelegate.velocity != velocity ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.glassiness != glassiness ||
        oldDelegate.borderRadius != borderRadius;
  }
}
