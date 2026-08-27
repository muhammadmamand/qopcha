import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_animations.dart';

/// Stable key for bottom-nav / shell tabs (one page per path).
LocalKey shellTabKey(GoRouterState state) =>
    ValueKey<String>('shell-tab:${state.matchedLocation}');

/// Page key for root-navigator overlays (`push` screens).
///
/// Combines go_router's unique [GoRouterState.pageKey] with the concrete URI
/// so stacked product pages and rematches never collide — and never equals
/// the shell's stable `app-shell` key.
LocalKey pageKeyForState(GoRouterState state) => ValueKey<String>(
      'overlay:${state.pageKey.value}:${state.uri}',
    );

CustomTransitionPage<T> fadeSlidePage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: pageKeyForState(state),
    child: child,
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppAnimations.smooth,
        reverseCurve: AppAnimations.exit,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<T> slideFromRightPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: pageKeyForState(state),
    child: child,
    transitionDuration: const Duration(milliseconds: 560),
    reverseTransitionDuration: const Duration(milliseconds: 440),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppAnimations.smooth,
        reverseCurve: AppAnimations.exit,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.035, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
