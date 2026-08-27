import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'animated_press.dart';

/// Photorealistic 4-hole clothing button.
class SewingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool loading;

  const SewingButton({
    super.key,
    this.onPressed,
    this.size = 112,
    this.loading = false,
  });

  static const asset = 'assets/images/sewing_button.png';

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return AnimatedPress(
      scale: 0.94,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.38),
                    blurRadius: size * 0.18,
                    offset: Offset(0, size * 0.08),
                  ),
                ],
              ),
              child: Image.asset(
                asset,
                width: size,
                height: size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stack) {
                  return CustomPaint(
                    size: Size.square(size),
                    painter: const _SewingButtonPainter(),
                  );
                },
              ),
            ),
            if (loading)
              SizedBox(
                width: size * 0.22,
                height: size * 0.22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SewingButtonPainter extends CustomPainter {
  const _SewingButtonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    const mid = Color(0xFF73B7D8);
    const highlight = Color(0xFFB7E0F2);
    const shade = Color(0xFF4A93B8);
    const deep = Color(0xFF2A5E78);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.42),
          colors: [highlight, mid, shade],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    canvas.drawCircle(
      c,
      r * 0.58,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.2, 0.25),
          colors: [mid, shade],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.58)),
    );

    final holeR = r * 0.075;
    final spread = r * 0.15;
    for (final o in const [
      Offset(-1, -1),
      Offset(1, -1),
      Offset(-1, 1),
      Offset(1, 1),
    ]) {
      canvas.drawCircle(c + o * spread, holeR, Paint()..color = deep);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
