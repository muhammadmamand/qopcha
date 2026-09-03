import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_color_theme.dart';
import 'app_theme.dart';

/// Soft floral wallpaper used by the girl-themed color packs.
class FloralBackdrop extends StatelessWidget {
  const FloralBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final motif = AppColors.colorTheme.floralMotif;
    if (motif == FloralMotif.none) return const SizedBox.shrink();

    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = AppColors.colorTheme.floralBackdrop(dark);

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: base,
          ),
        ),
        child: CustomPaint(
          painter: _FloralPainter(
            motif: motif,
            brand: AppColors.brand,
            highlight: AppColors.highlight,
            dark: dark,
          ),
        ),
      ),
    );
  }
}

class _FloralPainter extends CustomPainter {
  _FloralPainter({
    required this.motif,
    required this.brand,
    required this.highlight,
    required this.dark,
  });

  final FloralMotif motif;
  final Color brand;
  final Color highlight;
  final bool dark;

  static const _blooms = <Offset>[
    Offset(0.12, 0.10),
    Offset(0.86, 0.14),
    Offset(0.74, 0.42),
    Offset(0.18, 0.52),
    Offset(0.50, 0.72),
    Offset(0.90, 0.78),
    Offset(0.08, 0.86),
    Offset(0.38, 0.28),
    Offset(0.62, 0.90),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final accent = Color.lerp(brand, highlight, 0.45) ?? brand;
    final petal = (dark ? accent : brand).withValues(alpha: dark ? 0.22 : 0.16);
    final core = highlight.withValues(alpha: dark ? 0.34 : 0.28);
    final leaf = brand.withValues(alpha: dark ? 0.10 : 0.08);

    for (var i = 0; i < _blooms.length; i++) {
      final point = Offset(
        _blooms[i].dx * size.width,
        _blooms[i].dy * size.height,
      );
      final scale = switch (motif) {
        FloralMotif.rose => 0.9 + (i % 3) * 0.12,
        FloralMotif.blossom => 0.55 + (i % 4) * 0.08,
        FloralMotif.peony => 1.05 + (i % 2) * 0.18,
        FloralMotif.none => 1.0,
      };
      _drawBloom(
        canvas,
        point,
        scale,
        petal,
        core,
        leaf,
        rotate: i * 0.7,
      );
    }
  }

  void _drawBloom(
    Canvas canvas,
    Offset center,
    double scale,
    Color petal,
    Color core,
    Color leaf, {
    required double rotate,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotate);

    switch (motif) {
      case FloralMotif.rose:
        _rose(canvas, scale, petal, core, leaf);
      case FloralMotif.blossom:
        _blossom(canvas, scale, petal, core);
      case FloralMotif.peony:
        _peony(canvas, scale, petal, core, leaf);
      case FloralMotif.none:
        break;
    }

    canvas.restore();
  }

  void _rose(Canvas canvas, double scale, Color petal, Color core, Color leaf) {
    final r = 26.0 * scale;
    for (var i = 0; i < 7; i++) {
      final angle = i * math.pi * 2 / 7;
      final path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(math.cos(angle) * r * 0.34, math.sin(angle) * r * 0.34),
            width: r * 0.92,
            height: r * 0.56,
          ),
        );
      canvas.drawPath(path, Paint()..color = petal);
    }
    canvas.drawCircle(Offset.zero, r * 0.18, Paint()..color = core);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0, r * 0.72), width: r * 0.5, height: r * 0.22),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = leaf
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  void _blossom(Canvas canvas, double scale, Color petal, Color core) {
    final r = 18.0 * scale;
    for (var i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5 - math.pi / 2;
      canvas.drawCircle(
        Offset(math.cos(angle) * r * 0.42, math.sin(angle) * r * 0.42),
        r * 0.34,
        Paint()..color = petal,
      );
    }
    canvas.drawCircle(Offset.zero, r * 0.16, Paint()..color = core);
  }

  void _peony(Canvas canvas, double scale, Color petal, Color core, Color leaf) {
    final r = 30.0 * scale;
    for (var ring = 0; ring < 3; ring++) {
      final petals = 6 + ring * 2;
      final radius = r * (0.28 + ring * 0.18);
      for (var i = 0; i < petals; i++) {
        final angle = i * math.pi * 2 / petals + ring * 0.2;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
            width: r * 0.48,
            height: r * 0.34,
          ),
          Paint()..color = petal.withValues(alpha: petal.a * (1 - ring * 0.12)),
        );
      }
    }
    canvas.drawCircle(Offset.zero, r * 0.14, Paint()..color = core);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-r * 0.42, r * 0.55), width: r * 0.34, height: r * 0.14),
      Paint()..color = leaf,
    );
  }

  @override
  bool shouldRepaint(covariant _FloralPainter oldDelegate) {
    return oldDelegate.motif != motif ||
        oldDelegate.brand != brand ||
        oldDelegate.highlight != highlight ||
        oldDelegate.dark != dark;
  }
}
