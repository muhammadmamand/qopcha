import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/floral_background.dart';

/// Paints roses / blossoms behind page content for girl-themed color packs.
class FloralSceneWrapper extends StatelessWidget {
  final Widget child;

  const FloralSceneWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AppColors.colorTheme.isFloral) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ColoredBox(color: AppColors.surface),
        ),
        Positioned.fill(child: FloralBackdrop()),
        child,
      ],
    );
  }
}
