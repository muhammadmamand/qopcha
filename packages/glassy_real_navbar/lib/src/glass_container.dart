import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

/// Helper extension to use withValues instead of deprecated withOpacity
extension _ColorAlpha on Color {
  Color withAlpha2(double opacity) =>
      withValues(alpha: opacity.clamp(0.0, 1.0));
}

class GlassContainer extends StatefulWidget {
  final Widget? child;
  final double blur;
  final double opacity;
  final Color color;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  // Refraction factor (1.0 = no refraction, 1.05 = slight magnification)
  final double refraction;
  final double borderGradientOpacity;
  final double
      glassiness; // [NEW] Impact of lighting/realism (replaces reactiveness)
  final double borderLightSource; // [NEW] Rotation of border light

  final Alignment? spotlightCenter; // The center of the "liquid" source
  final Color spotlightColor;
  // Optional: Global focal point for the refraction lens (Screen coordinates)
  // If null, the container attempts to auto-detect its own center.
  final Offset? focalPoint;

  const GlassContainer({
    super.key,
    this.child,
    this.blur = 3.0, // Ultra clear liquid look
    this.opacity = 0.05, // Very transparent
    this.refraction = 1.25, // Strong distortion (Magnification)
    this.color = Colors.white,
    this.gradient,
    this.borderRadius,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.alignment,
    this.borderGradientOpacity = 0.5,
    this.spotlightCenter,
    this.spotlightColor = Colors.white,
    this.focalPoint,
    this.glassiness = 1.0, // [NEW] Controls how "shiny" the border looks
    this.borderLightSource = 0.785, // approx pi/4
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  final GlobalKey _key = GlobalKey();
  Offset? _autoFocalPoint;

  @override
  void initState() {
    super.initState();
    // Schedule position check
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePosition());
  }

  void _updatePosition() {
    if (!mounted) return;
    final RenderBox? box =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final Offset topLeft = box.localToGlobal(Offset.zero);
      final Size size = box.size;
      final Offset center = topLeft + Offset(size.width / 2, size.height / 2);

      if (_autoFocalPoint != center) {
        setState(() {
          _autoFocalPoint = center;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(20);

    // Use provided focal point OR auto-detected one
    final Offset? targetFocalPoint = widget.focalPoint ?? _autoFocalPoint;

    // Create the optical filter: Blur + Refraction (Scale)
    ImageFilter filter =
        ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur);

    if (widget.refraction != 1.0) {
      // Composition: Scale (Refraction) -> Blur
      // We scale up to simulate the "magnifying" property of thick convex glass
      // Anchor the scale to the focal point to prevent the "sliding background" effect.
      if (targetFocalPoint != null) {
        final matrix = Matrix4.identity()
          ..translateByVector3(
              vm.Vector3(targetFocalPoint.dx, targetFocalPoint.dy, 0))
          ..scaleByVector3(
              vm.Vector3(widget.refraction, widget.refraction, 1.0))
          ..translateByVector3(
              vm.Vector3(-targetFocalPoint.dx, -targetFocalPoint.dy, 0));
        filter = ImageFilter.compose(
          outer: filter,
          inner: ImageFilter.matrix(matrix.storage),
        );
      } else {
        // Fallback if we haven't calculated position yet (first frame):
        // Just return blur, or do un-anchored scale (might look weird for 1 frame).
        // Better to return just blur to avoid jump.
        // Or strictly apply scale if user forces it?
        // Let's default to just blur until we know where we are.
      }
    }

    return Container(
      key: _key,
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: Stack(
        children: [
          // 1. Optical Layer (Blur + Refraction)
          ClipRRect(
            borderRadius: effectiveBorderRadius,
            child: BackdropFilter(
              filter: filter,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color.withAlpha2(widget.opacity),
                  borderRadius: effectiveBorderRadius,
                  // Use a simpler gradient that respects the user's opacity choice directly
                  gradient: widget.gradient ??
                      LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.color.withAlpha2(widget.opacity),
                          widget.color.withAlpha2(
                              (widget.opacity * 0.8).clamp(0.0, 1.0)),
                        ],
                      ),
                ),
              ),
            ),
          ),

          // 2. Static Glass Border (Base Reflection)
          IgnorePointer(
            child: CustomPaint(
              painter: _GlassBorderPainter(
                borderRadius: effectiveBorderRadius,
                opacity: widget.borderGradientOpacity,
                glassiness: widget.glassiness,
                lightAngle: widget.borderLightSource,
              ),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: effectiveBorderRadius,
                ),
              ),
            ),
          ),

          // 3. Dynamic Spotlight Border (Liquid Edge)
          if (widget.spotlightCenter != null)
            IgnorePointer(
              child: CustomPaint(
                painter: _SpotlightBorderPainter(
                  borderRadius: effectiveBorderRadius,
                  spotlightCenter: widget.spotlightCenter!,
                  color: widget.spotlightColor,
                  glassiness: widget.glassiness,
                ),
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: effectiveBorderRadius,
                  ),
                ),
              ),
            ),

          // 4. Content
          Container(
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            alignment: widget.alignment,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _GlassBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double opacity;
  final double glassiness; // Replaced reactiveness
  final double lightAngle;

  _GlassBorderPainter({
    required this.borderRadius,
    required this.opacity,
    required this.glassiness,
    required this.lightAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect rrect = borderRadius.toRRect(rect);

    // Realistic Glass Edge (Fresnel-like)
    // We use a diagonal gradient with alternating distinct light/dark bands
    // to simulate light catching the edges of thick glass.
    final Paint mainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 + (1.5 * glassiness) // Thicker if more glassy
      ..blendMode = BlendMode.overlay // Overlay for interaction with background
      ..shader = LinearGradient(
        begin: Alignment.topLeft, // Default base
        end: Alignment.bottomRight,
        transform: GradientRotation(
            lightAngle - 0.785), // Rotate relative to default diagonal
        colors: [
          Colors.white
              .withAlpha2((0.6 * glassiness).clamp(0.0, 1.0)), // Highlight
          Colors.white.withAlpha2(0.05), // Clear/Dark gap
          Colors.white
              .withAlpha2((0.3 * glassiness).clamp(0.0, 1.0)), // Mid-tone
          Colors.black
              .withAlpha2((0.2 * glassiness).clamp(0.0, 1.0)), // Shadow/Depth
          Colors.white
              .withAlpha2((0.5 * glassiness).clamp(0.0, 1.0)), // Final glint
        ],
        stops: const [0.0, 0.3, 0.5, 0.8, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, mainPaint);

    // Additional inner shine for extra realism if highly glassy
    if (glassiness > 0.5) {
      final Paint innerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withAlpha2((0.4 * glassiness).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
        ).createShader(rect);
      // Deflate slightly to be "inner"
      canvas.drawRRect(rrect.deflate(1.0), innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter old) {
    return old.glassiness != glassiness || old.opacity != opacity;
  }
}

class _SpotlightBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Alignment spotlightCenter;
  final Color color;
  final double glassiness;

  _SpotlightBorderPainter({
    required this.borderRadius,
    required this.spotlightCenter,
    required this.color,
    required this.glassiness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (glassiness <= 0.0) return; // Optimization

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect rrect = borderRadius.toRRect(rect);

    // Create a radial gradient mask for the border
    // This allows the border to "glow" near the spotlight center
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * glassiness // Slightly thicker for the glow
      ..shader = RadialGradient(
        center: spotlightCenter,
        radius: 0.8, // Adjust for spread
        colors: [
          color.withAlpha2((0.8 * glassiness).clamp(0.0, 1.0)),
          color.withAlpha2(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightBorderPainter oldDelegate) {
    return oldDelegate.spotlightCenter != spotlightCenter ||
        oldDelegate.color != color ||
        oldDelegate.glassiness != glassiness;
  }
}
