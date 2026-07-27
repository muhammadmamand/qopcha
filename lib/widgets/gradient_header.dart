import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_animations.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_theme.dart';

class GradientHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double height;
  final Widget? child;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.height = 180,
    this.child,
  });

  @override
  State<GradientHeader> createState() => _GradientHeaderState();
}

class _GradientHeaderState extends State<GradientHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -30 + (_orbController.value * 20),
                    right: -20,
                    child: _GlowOrb(
                      size: 140,
                      color: AppColors.secondary.withValues(alpha: 0.18),
                    ),
                  ),
                  Positioned(
                    bottom: 20 - (_orbController.value * 15),
                    left: -40,
                    child: _GlowOrb(
                      size: 100,
                      color: AppColors.gold.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                  ),
                                )
                                .animate()
                                .fadeIn(
                                  duration: AppAnimations.slow,
                                  curve: AppAnimations.smooth,
                                )
                                .slideY(
                                  begin: 0.15,
                                  curve: AppAnimations.smooth,
                                ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                    widget.subtitle!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: 120.ms,
                                    duration: AppAnimations.slow,
                                    curve: AppAnimations.smooth,
                                  )
                                  .slideY(
                                    begin: 0.1,
                                    curve: AppAnimations.smooth,
                                  ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.trailing != null)
                        widget.trailing!
                            .animate()
                            .fadeIn(
                              delay: 200.ms,
                              duration: AppAnimations.normal,
                            )
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              curve: AppAnimations.bounce,
                            ),
                    ],
                  ),
                  if (widget.child != null) ...[
                    const SizedBox(height: 20),
                    widget.child!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const GlassIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppDecorations.glass(radius: 16),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
