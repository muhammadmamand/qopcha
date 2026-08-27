import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Telegram-style circular wipe when switching light/dark theme.
/// Both directions use the same expand animation from the tap point.
class TelegramThemeReveal extends StatefulWidget {
  final Widget child;

  const TelegramThemeReveal({super.key, required this.child});

  static TelegramThemeRevealState? of(BuildContext context) {
    return context.findAncestorStateOfType<TelegramThemeRevealState>();
  }

  static Offset centerFrom(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      final size = MediaQuery.sizeOf(context);
      return Offset(size.width / 2, size.height / 2);
    }
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  State<TelegramThemeReveal> createState() => TelegramThemeRevealState();
}

class TelegramThemeRevealState extends State<TelegramThemeReveal>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 700);
  static const _curve = Curves.easeInOutCubic;

  final GlobalKey _boundaryKey = GlobalKey();

  late final AnimationController _controller;
  ui.Image? _snapshot;
  Offset _center = Offset.zero;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
  }

  @override
  void dispose() {
    _snapshot?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _waitFrames([int count = 1]) async {
    for (var i = 0; i < count; i++) {
      final done = Completer<void>();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!done.isCompleted) done.complete();
      });
      await done.future;
    }
  }

  /// Same expand animation for light→dark and dark→light.
  Future<void> reveal({
    required Offset center,
    required VoidCallback onThemeChange,
    bool reverse = false, // kept for call-site compat; always expands
  }) async {
    if (_busy) return;
    _busy = true;

    try {
      await _waitFrames(1);
      if (!mounted) return;

      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize) {
        onThemeChange();
        return;
      }

      final localCenter = boundary.globalToLocal(center);
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final image = await boundary.toImage(pixelRatio: dpr);
      if (!mounted) {
        image.dispose();
        return;
      }

      _controller.value = 0;

      setState(() {
        _snapshot?.dispose();
        _snapshot = image;
        _center = localCenter;
      });

      await _waitFrames(2);
      if (!mounted) return;
      onThemeChange();
      await _waitFrames(1);
      if (!mounted) return;

      await _controller.animateTo(1.0, duration: _duration, curve: _curve);

      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    } finally {
      if (mounted) {
        setState(() {
          _snapshot?.dispose();
          _snapshot = null;
          _busy = false;
        });
        _controller.value = 0;
      } else {
        _snapshot?.dispose();
        _snapshot = null;
        _busy = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: widget.child,
        ),
        if (_snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _RevealPainter(
                      image: _snapshot!,
                      center: _center,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _RevealPainter extends CustomPainter {
  final ui.Image image;
  final Offset center;
  final double progress;

  _RevealPainter({
    required this.image,
    required this.center,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxRadius = _maxRadius(size, center) * 1.02;
    final radius = maxRadius * progress.clamp(0.0, 1.0);
    final rect = Offset.zero & size;

    canvas.saveLayer(rect, Paint());

    paintImage(
      canvas: canvas,
      rect: rect,
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );

    // Growing hole → new theme expands from the tap (light and dark).
    if (radius > 0.5) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..color = Colors.white
          ..isAntiAlias = true,
      );

      final edge = (1.0 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0);
      if (edge > 0.05) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12 * edge
            ..color = Colors.white.withValues(alpha: 0.08 * edge)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
            ..isAntiAlias = true,
        );
      }
    }

    canvas.restore();
  }

  static double _maxRadius(Size size, Offset center) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    var max = 0.0;
    for (final c in corners) {
      max = math.max(max, (c - center).distance);
    }
    return max;
  }

  @override
  bool shouldRepaint(covariant _RevealPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.center != center ||
        oldDelegate.image != image;
  }
}
