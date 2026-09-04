import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_animations.dart';
import '../core/theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    // Web hot-restart + repeating tickers → disposed EngineFlutterView asserts.
    final loader = kIsWeb
        ? const SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(painter: _RingLoaderPainter(0.35)),
          )
        : const _PremiumLoader()
            .animate()
            .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              duration: 650.ms,
              curve: Curves.easeOutCubic,
            );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          loader,
          if (message != null) ...[
            const SizedBox(height: 22),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PremiumLoader extends StatefulWidget {
  const _PremiumLoader();

  @override
  State<_PremiumLoader> createState() => _PremiumLoaderState();
}

class _PremiumLoaderState extends State<_PremiumLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(
            painter: _RingLoaderPainter(_controller.value),
          ),
        );
      },
    );
  }
}

class _RingLoaderPainter extends CustomPainter {
  final double t;

  const _RingLoaderPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final track = Paint()
      ..color = AppColors.brand.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    final sweep = 1.6 + (0.6 * (0.5 + 0.5 * math.sin(t * math.pi * 2)));
    final start = t * math.pi * 2;

    final active = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        colors: [
          AppColors.brand.withValues(alpha: 0.05),
          AppColors.brand,
          AppColors.highlight,
          AppColors.brand.withValues(alpha: 0.05),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
        transform: GradientRotation(start),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _RingLoaderPainter oldDelegate) =>
      oldDelegate.t != t;
}

class ProductGridShimmer extends StatelessWidget {
  final int count;

  const ProductGridShimmer({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.54,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      itemCount: count,
      itemBuilder: (_, index) => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class ErrorView extends ConsumerWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: AppColors.error,
              ),
            ).animate().scale(curve: AppAnimations.bounce),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(s.tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? iconWidget;
  final Widget? action;

  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.iconWidget,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxHeight.isFinite &&
            constraints.maxHeight < 260;
        final pad = tight ? 16.0 : 40.0;
        final iconPad = tight ? 16.0 : 28.0;
        final iconSize = tight ? 36.0 : 56.0;
        final gap = tight ? 12.0 : 24.0;

        return Center(
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth.isFinite
                      ? constraints.maxWidth - pad * 2
                      : 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                          padding: EdgeInsets.all(iconPad),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: iconWidget ??
                              Icon(
                                icon,
                                size: iconSize,
                                color: AppColors.textTertiary,
                              ),
                        )
                        .animate()
                        .fadeIn(duration: AppAnimations.slow)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          curve: AppAnimations.bounce,
                        ),
                    SizedBox(height: gap),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: tight ? 14 : 16,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    if (action != null) ...[
                      SizedBox(height: gap),
                      action!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
