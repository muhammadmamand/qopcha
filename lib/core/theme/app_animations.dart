import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  static const fast = Duration(milliseconds: 320);
  static const normal = Duration(milliseconds: 520);
  static const slow = Duration(milliseconds: 760);
  static const cinematic = Duration(milliseconds: 1100);

  static const smooth = Curves.easeOutCubic;
  static const bounce = Curves.easeOutCubic;
  static const enter = Curves.easeOutQuart;
  static const exit = Curves.easeInCubic;

  static List<Effect> staggerIn(int index, {double offset = 24}) => [
        FadeEffect(
          duration: normal,
          delay: (index * 80).ms,
          curve: smooth,
        ),
        SlideEffect(
          begin: Offset(0, offset / 100),
          end: Offset.zero,
          duration: slow,
          delay: (index * 80).ms,
          curve: smooth,
        ),
      ];

  static List<Effect> fadeUp({Duration? delay}) => [
        FadeEffect(duration: normal, delay: delay, curve: smooth),
        SlideEffect(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
          duration: slow,
          delay: delay,
          curve: smooth,
        ),
      ];
}

extension AnimateExtension on Widget {
  Widget animateStagger(int index) => animate(effects: AppAnimations.staggerIn(index));
  Widget animateFadeUp({Duration? delay}) => animate(effects: AppAnimations.fadeUp(delay: delay));
}
