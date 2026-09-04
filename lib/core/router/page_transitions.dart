import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_animations.dart';

/// Stable key for bottom-nav / shell tabs (one page per path, ignores query).
LocalKey shellTabKey(GoRouterState state) =>
    ValueKey<String>('shell-tab:${state.matchedLocation}');

/// Page key for pushed overlays — prefer go_router's unique [GoRouterState.pageKey]
/// (imperative pushes already get a unique key) and never collide with tab keys.
LocalKey pageKeyForState(GoRouterState state) => state.pageKey;

/// Routes shown inside the shell without the bottom navigation bar.
bool isShellOverlayLocation(String location) {
  final raw = location.trim();
  if (raw.isEmpty) return false;
  final path = (Uri.tryParse(raw)?.path ?? raw).split('?').first;
  final normalized = path.startsWith('/') ? path : '/$path';
  return normalized.startsWith('/notifications') ||
      normalized.startsWith('/product/') ||
      normalized.startsWith('/store/') ||
      normalized.startsWith('/settings') ||
      normalized.contains('/shop/add-product') ||
      normalized.contains('/shop/edit-product') ||
      normalized.endsWith('/add-product') ||
      normalized.contains('/edit-product/');
}

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
