import 'package:flutter/material.dart';

/// Fabric-roll glyph used across shop/customer fabric UI.
class FabricIcon extends StatelessWidget {
  static const asset = 'assets/images/category/fabric.png';

  final double size;
  final Color? color;

  const FabricIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? IconTheme.of(context).color ?? Colors.white;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
