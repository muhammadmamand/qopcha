import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Clearance for content above the notched bar + floating bubble.
const double kPremiumBottomNavClearance = 96;

const Duration _kMove = Duration(milliseconds: 820);
const Duration _kPress = Duration(milliseconds: 180);
/// Soft ease-out — slow start, very gentle settle (no snap).
const Curve _kSmooth = Cubic(0.33, 1.15, 0.42, 1.0);

const double _kBarH = 58;
const double _kFabSize = 42;
const double _kNotchRadius = 26;
const double _kTopCorner = 24;
const double _kFabLift = 22;
const double _kSidePad = 8;

class PremiumBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final List<int?> badges;
  final List<int> animatedIndexes;

  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.badges = const [],
    this.animatedIndexes = const [],
  });

  @override
  State<PremiumBottomNav> createState() => _PremiumBottomNavState();
}

class _PremiumBottomNavState extends State<PremiumBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _fromSlot = 0;
  double _toSlot = 0;
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _fromSlot = widget.currentIndex.toDouble();
    _toSlot = _fromSlot;
    _controller = AnimationController(vsync: this, duration: _kMove)
      ..value = 1;
  }

  @override
  void didUpdateWidget(covariant PremiumBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _fromSlot = _currentSlot;
      _toSlot = widget.currentIndex.toDouble();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _currentSlot {
    final t = _kSmooth.transform(_controller.value);
    return lerpDouble(_fromSlot, _toSlot, t)!;
  }

  void _tap(int index) {
    if (index == widget.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.onTap(index);
  }

  double _slotCenterX(double width, int count, double slot) {
    final usable = width - (_kSidePad * 2);
    final slotW = usable / count;
    return _kSidePad + slotW * (slot + 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final barColor = AppColors.isDark ? AppColors.card : Colors.white;
    final iconIdle = AppColors.isDark
        ? AppColors.textTertiary
        : const Color(0xFFB8B8C0);
    final iconActive = AppColors.isDark
        ? AppColors.textPrimary
        : const Color(0xFF2A2A32);
    final fabBorder = AppColors.isDark
        ? AppColors.border
        : const Color(0xFF1A1A1A);

    final totalH = _kBarH + _kFabLift + bottomInset;
    final activeItem = items[widget.currentIndex.clamp(0, items.length - 1)];
    final activeBadge = widget.currentIndex < widget.badges.length
        ? widget.badges[widget.currentIndex]
        : null;

    return SizedBox(
      height: totalH,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final slot = _currentSlot.clamp(
                0.0,
                (items.length - 1).toDouble(),
              );
              final cx = _slotCenterX(w, items.length, slot);
              final fabLeft = cx - (_kFabSize / 2);
              final fabBottom =
                  bottomInset + _kBarH - (_kFabSize / 2) - 2;

              // Very soft lift while traveling — almost flat.
              final t = _controller.value;
              final bob = (t > 0 && t < 1)
                  ? -2.0 * Curves.easeInOut.transform(4 * t * (1 - t))
                  : 0.0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _kBarH + bottomInset,
                    child: CustomPaint(
                      painter: _NotchedBarPainter(
                        color: barColor,
                        topCorner: _kTopCorner,
                        notchRadius: _kNotchRadius,
                        notchCenterX: cx,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomInset,
                    height: _kBarH,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _kSidePad,
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i < items.length; i++)
                              Expanded(
                                child: _SideTab(
                                  item: items[i],
                                  visible: (slot - i).abs() > 0.42,
                                  pressed: _pressedIndex == i,
                                  badge: i < widget.badges.length
                                      ? widget.badges[i]
                                      : null,
                                  idleColor: iconIdle,
                                  onTap: () => _tap(i),
                                  onTapDown: () =>
                                      setState(() => _pressedIndex = i),
                                  onTapUp: () => setState(
                                    () => _pressedIndex = null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: fabLeft,
                    bottom: fabBottom - bob,
                    child: _FloatingBubble(
                      item: activeItem,
                      badge: activeBadge,
                      barColor: barColor,
                      borderColor: fabBorder,
                      iconColor: iconActive,
                      pressed: _pressedIndex == widget.currentIndex,
                      onTap: () => _tap(widget.currentIndex),
                      onTapDown: () => setState(
                        () => _pressedIndex = widget.currentIndex,
                      ),
                      onTapUp: () =>
                          setState(() => _pressedIndex = null),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SideTab extends StatelessWidget {
  final NavItem item;
  final bool visible;
  final bool pressed;
  final int? badge;
  final Color idleColor;
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _SideTab({
    required this.item,
    required this.visible,
    required this.pressed,
    this.badge,
    required this.idleColor,
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: AnimatedScale(
        scale: pressed ? 0.9 : 1,
        duration: _kPress,
        curve: _kSmooth,
        child: SizedBox(
          height: _kBarH,
          child: Center(
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(item.icon, size: 24, color: idleColor),
                  if (badge != null && badge! > 0)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: _Badge(count: badge!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingBubble extends StatelessWidget {
  final NavItem item;
  final int? badge;
  final Color barColor;
  final Color borderColor;
  final Color iconColor;
  final bool pressed;
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _FloatingBubble({
    required this.item,
    this.badge,
    required this.barColor,
    required this.borderColor,
    required this.iconColor,
    required this.pressed,
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: AnimatedScale(
        scale: pressed ? 0.92 : 1,
        duration: _kPress,
        curve: _kSmooth,
        child: Container(
          width: _kFabSize,
          height: _kFabSize,
          decoration: BoxDecoration(
            color: barColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  item.activeIcon,
                  key: ValueKey('${item.label}-${item.activeIcon.codePoint}'),
                  size: 22,
                  color: iconColor,
                ),
              ),
              if (badge != null && badge! > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _Badge(count: badge!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: AppColors.highlight,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          height: 1,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  final Color color;
  final double topCorner;
  final double notchRadius;
  final double notchCenterX;

  const _NotchedBarPainter({
    required this.color,
    required this.topCorner,
    required this.notchRadius,
    required this.notchCenterX,
  });

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final r = topCorner;
    final cx = notchCenterX.clamp(notchRadius + r, w - notchRadius - r);
    final notchR = notchRadius;

    final path = Path();
    path.moveTo(0, h);
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);

    path.lineTo(cx - notchR, 0);
    path.arcToPoint(
      Offset(cx + notchR, 0),
      radius: Radius.circular(notchR),
      clockwise: false,
    );

    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, h);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.16),
      14,
      false,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.topCorner != topCorner ||
        oldDelegate.notchRadius != notchRadius ||
        oldDelegate.notchCenterX != notchCenterX;
  }
}
