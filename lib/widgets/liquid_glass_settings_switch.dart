import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../core/theme/app_theme.dart';

/// Settings-row toggle with the same liquid-glass thumb as the bottom nav.
class LiquidGlassSettingsSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const LiquidGlassSettingsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final brand = AppColors.brand;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final switchWidget = LiquidGlassSwitch(
      value: value,
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
      width: 64,
      height: 32,
      activeColor: brand,
      inactiveColor: dark
          ? const Color(0x4C787880)
          : AppColors.border.withValues(alpha: 0.85),
      thumbColor: Colors.white,
      reserveSwellRoom: true,
      pixelRatio: 1,
      style: LiquidGlassSwitch.defaultStyle.copyWith(
        refraction: const LiquidGlassRefraction(
          distortion: 0.06,
          distortionWidth: 14,
          chromaticAberration: 0.002,
        ),
      ),
    );

    // LiquidGlassSwitch is LTR-only: OFF=left, ON=right. Mirror for RTL so
    // ON sits on the left (swipe right → left to enable), like iOS Arabic.
    if (!isRtl) return switchWidget;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Transform.flip(
        flipX: true,
        child: switchWidget,
      ),
    );
  }
}
