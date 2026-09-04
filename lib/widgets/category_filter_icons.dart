import 'package:flutter/material.dart';

/// Line-art category glyphs for the home filter row (screenshot style).
class CategoryFilterIcon extends StatelessWidget {
  final String category;
  final Color color;
  final double size;

  const CategoryFilterIcon({
    super.key,
    required this.category,
    required this.color,
    this.size = 26,
  });

  static const _assetIcons = <String, String>{
    'پۆشاک': 'assets/images/category/t_shirt.png',
    'کراس': 'assets/images/category/shirt.png',
    'پێڵاو': 'assets/images/category/shoes.png',
    'جلوبەرگی فەرمی': 'assets/images/category/formal.png',
    'جانتە': 'assets/images/category/bag.png',
    'کڵاو': 'assets/images/category/cap.png',
    'جلوبەرگی وەرزشی': 'assets/images/category/sports.png',
    'قوماش': 'assets/images/category/fabric.png',
  };

  @override
  Widget build(BuildContext context) {
    final asset = _assetIcons[category];
    if (asset != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
    }

    return CustomPaint(
      size: Size.square(size),
      painter: _CategoryIconPainter(category: category, color: color),
    );
  }
}

class _CategoryIconPainter extends CustomPainter {
  final String category;
  final Color color;

  _CategoryIconPainter({required this.category, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    switch (category) {
      case 'هەموو':
        _grid(canvas, s, stroke, fill);
      case 'پۆشاک':
        _tshirt(canvas, s, stroke);
      case 'پانتۆڵ':
        _pants(canvas, s, stroke);
      case 'کراس':
        _dress(canvas, s, stroke);
      case 'کۆت':
        _jacket(canvas, s, stroke);
      case 'پێڵاو':
        _shoe(canvas, s, stroke);
      case 'ئاکسەسوار':
        _accessory(canvas, s, stroke);
      case 'جلوبەرگی وەرزشی':
        _hoodie(canvas, s, stroke);
      case 'جلوبەرگی فەرمی':
        _shirt(canvas, s, stroke);
      case 'کڵاو':
        _hat(canvas, s, stroke);
      case 'جانتە':
        _bag(canvas, s, stroke);
      case 'کاتژمێر':
        _watch(canvas, s, stroke);
      case 'جلی منداڵان':
        _kids(canvas, s, stroke);
      default:
        _tshirt(canvas, s, stroke);
    }

    canvas.restore();
  }

  void _grid(Canvas canvas, double s, Paint stroke, Paint fill) {
    final gap = s * 0.12;
    final cell = (s - gap) / 2;
    final r = Radius.circular(s * 0.06);
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(col * (cell + gap), row * (cell + gap), cell, cell),
          r,
        );
        canvas.drawRRect(rect, stroke);
      }
    }
  }

  void _tshirt(Canvas canvas, double s, Paint p) {
    final path = Path()
      ..moveTo(s * 0.32, s * 0.22)
      ..lineTo(s * 0.38, s * 0.14)
      ..quadraticBezierTo(s * 0.50, s * 0.08, s * 0.62, s * 0.14)
      ..lineTo(s * 0.68, s * 0.22)
      ..lineTo(s * 0.90, s * 0.34)
      ..lineTo(s * 0.82, s * 0.46)
      ..lineTo(s * 0.70, s * 0.38)
      ..lineTo(s * 0.70, s * 0.88)
      ..lineTo(s * 0.30, s * 0.88)
      ..lineTo(s * 0.30, s * 0.38)
      ..lineTo(s * 0.18, s * 0.46)
      ..lineTo(s * 0.10, s * 0.34)
      ..close();
    canvas.drawPath(path, p);
  }

  void _shirt(Canvas canvas, double s, Paint p) {
    final path = Path()
      ..moveTo(s * 0.34, s * 0.20)
      ..lineTo(s * 0.42, s * 0.12)
      ..lineTo(s * 0.50, s * 0.22)
      ..lineTo(s * 0.58, s * 0.12)
      ..lineTo(s * 0.66, s * 0.20)
      ..lineTo(s * 0.88, s * 0.32)
      ..lineTo(s * 0.80, s * 0.44)
      ..lineTo(s * 0.70, s * 0.36)
      ..lineTo(s * 0.70, s * 0.90)
      ..lineTo(s * 0.30, s * 0.90)
      ..lineTo(s * 0.30, s * 0.36)
      ..lineTo(s * 0.20, s * 0.44)
      ..lineTo(s * 0.12, s * 0.32)
      ..close();
    canvas.drawPath(path, p);
    // pocket
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.54, s * 0.40, s * 0.14, s * 0.14),
        Radius.circular(s * 0.02),
      ),
      p,
    );
  }

  void _hoodie(Canvas canvas, double s, Paint p) {
    // hood
    canvas.drawArc(
      Rect.fromLTWH(s * 0.28, s * 0.06, s * 0.44, s * 0.36),
      3.4,
      2.5,
      false,
      p,
    );
    final body = Path()
      ..moveTo(s * 0.30, s * 0.32)
      ..lineTo(s * 0.14, s * 0.42)
      ..lineTo(s * 0.22, s * 0.54)
      ..lineTo(s * 0.30, s * 0.48)
      ..lineTo(s * 0.30, s * 0.90)
      ..lineTo(s * 0.70, s * 0.90)
      ..lineTo(s * 0.70, s * 0.48)
      ..lineTo(s * 0.78, s * 0.54)
      ..lineTo(s * 0.86, s * 0.42)
      ..lineTo(s * 0.70, s * 0.32)
      ..quadraticBezierTo(s * 0.50, s * 0.40, s * 0.30, s * 0.32);
    canvas.drawPath(body, p);
    // pouch
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.36, s * 0.58, s * 0.28, s * 0.18),
        Radius.circular(s * 0.04),
      ),
      p,
    );
  }

  void _jacket(Canvas canvas, double s, Paint p) {
    final path = Path()
      ..moveTo(s * 0.32, s * 0.20)
      ..lineTo(s * 0.40, s * 0.12)
      ..lineTo(s * 0.50, s * 0.22)
      ..lineTo(s * 0.60, s * 0.12)
      ..lineTo(s * 0.68, s * 0.20)
      ..lineTo(s * 0.92, s * 0.34)
      ..lineTo(s * 0.82, s * 0.48)
      ..lineTo(s * 0.72, s * 0.40)
      ..lineTo(s * 0.72, s * 0.90)
      ..lineTo(s * 0.28, s * 0.90)
      ..lineTo(s * 0.28, s * 0.40)
      ..lineTo(s * 0.18, s * 0.48)
      ..lineTo(s * 0.08, s * 0.34)
      ..close();
    canvas.drawPath(path, p);
    // open zipper lines
    canvas.drawLine(
      Offset(s * 0.50, s * 0.28),
      Offset(s * 0.42, s * 0.90),
      p,
    );
    canvas.drawLine(
      Offset(s * 0.50, s * 0.28),
      Offset(s * 0.58, s * 0.90),
      p,
    );
  }

  void _dress(Canvas canvas, double s, Paint p) {
    final path = Path()
      ..moveTo(s * 0.36, s * 0.14)
      ..lineTo(s * 0.42, s * 0.28)
      ..lineTo(s * 0.30, s * 0.34)
      ..lineTo(s * 0.18, s * 0.90)
      ..lineTo(s * 0.82, s * 0.90)
      ..lineTo(s * 0.70, s * 0.34)
      ..lineTo(s * 0.58, s * 0.28)
      ..lineTo(s * 0.64, s * 0.14)
      ..quadraticBezierTo(s * 0.50, s * 0.06, s * 0.36, s * 0.14);
    canvas.drawPath(path, p);
  }

  void _shoe(Canvas canvas, double s, Paint p) {
    final path = Path()
      ..moveTo(s * 0.12, s * 0.58)
      ..quadraticBezierTo(s * 0.18, s * 0.34, s * 0.42, s * 0.36)
      ..quadraticBezierTo(s * 0.62, s * 0.38, s * 0.72, s * 0.48)
      ..quadraticBezierTo(s * 0.92, s * 0.52, s * 0.90, s * 0.68)
      ..lineTo(s * 0.14, s * 0.72)
      ..quadraticBezierTo(s * 0.08, s * 0.68, s * 0.12, s * 0.58);
    canvas.drawPath(path, p);
    canvas.drawLine(
      Offset(s * 0.42, s * 0.52),
      Offset(s * 0.58, s * 0.58),
      p,
    );
  }

  void _pants(Canvas canvas, double s, Paint p) {
    final path = Path()
      ..moveTo(s * 0.28, s * 0.12)
      ..lineTo(s * 0.72, s * 0.12)
      ..lineTo(s * 0.76, s * 0.90)
      ..lineTo(s * 0.56, s * 0.90)
      ..lineTo(s * 0.50, s * 0.42)
      ..lineTo(s * 0.44, s * 0.90)
      ..lineTo(s * 0.24, s * 0.90)
      ..close();
    canvas.drawPath(path, p);
  }

  void _accessory(Canvas canvas, double s, Paint p) {
    // simple diamond / gem
    final path = Path()
      ..moveTo(s * 0.50, s * 0.12)
      ..lineTo(s * 0.78, s * 0.38)
      ..lineTo(s * 0.50, s * 0.88)
      ..lineTo(s * 0.22, s * 0.38)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawLine(Offset(s * 0.22, s * 0.38), Offset(s * 0.78, s * 0.38), p);
  }

  void _hat(Canvas canvas, double s, Paint p) {
    canvas.drawArc(
      Rect.fromLTWH(s * 0.28, s * 0.18, s * 0.44, s * 0.40),
      3.14,
      3.14,
      false,
      p,
    );
    canvas.drawLine(
      Offset(s * 0.14, s * 0.58),
      Offset(s * 0.86, s * 0.58),
      p,
    );
    canvas.drawArc(
      Rect.fromLTWH(s * 0.14, s * 0.48, s * 0.72, s * 0.22),
      0,
      3.14,
      false,
      p,
    );
  }

  void _bag(Canvas canvas, double s, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.22, s * 0.36, s * 0.56, s * 0.50),
        Radius.circular(s * 0.06),
      ),
      p,
    );
    canvas.drawArc(
      Rect.fromLTWH(s * 0.34, s * 0.14, s * 0.32, s * 0.30),
      3.14,
      3.14,
      false,
      p,
    );
  }

  void _watch(Canvas canvas, double s, Paint p) {
    canvas.drawCircle(Offset(s * 0.50, s * 0.50), s * 0.26, p);
    canvas.drawLine(
      Offset(s * 0.50, s * 0.50),
      Offset(s * 0.50, s * 0.36),
      p,
    );
    canvas.drawLine(
      Offset(s * 0.50, s * 0.50),
      Offset(s * 0.62, s * 0.50),
      p,
    );
    canvas.drawLine(
      Offset(s * 0.42, s * 0.12),
      Offset(s * 0.58, s * 0.12),
      p,
    );
    canvas.drawLine(
      Offset(s * 0.42, s * 0.88),
      Offset(s * 0.58, s * 0.88),
      p,
    );
    canvas.drawLine(
      Offset(s * 0.46, s * 0.12),
      Offset(s * 0.46, s * 0.24),
      p,
    );
    canvas.drawLine(
      Offset(s * 0.54, s * 0.12),
      Offset(s * 0.54, s * 0.24),
      p,
    );
    canvas.drawLine(
      Offset(s * 0.46, s * 0.76),
      Offset(s * 0.46, s * 0.88),
      p,
    );
    canvas.drawLine(
      Offset(s * 0.54, s * 0.76),
      Offset(s * 0.54, s * 0.88),
      p,
    );
  }

  void _kids(Canvas canvas, double s, Paint p) {
    canvas.drawCircle(Offset(s * 0.50, s * 0.28), s * 0.14, p);
    final body = Path()
      ..moveTo(s * 0.28, s * 0.88)
      ..lineTo(s * 0.34, s * 0.52)
      ..quadraticBezierTo(s * 0.50, s * 0.44, s * 0.66, s * 0.52)
      ..lineTo(s * 0.72, s * 0.88);
    canvas.drawPath(body, p);
  }

  @override
  bool shouldRepaint(covariant _CategoryIconPainter oldDelegate) {
    return oldDelegate.category != category || oldDelegate.color != color;
  }
}
