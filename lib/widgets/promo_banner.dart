import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../models/banner_model.dart';
import '../providers/admin_provider.dart';

class PromoBannerData {
  final String title;
  final String highlight;
  final String subtitle;
  final String cta;
  final String tag;
  final String imageUrl;
  final List<Color> colors;

  const PromoBannerData({
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.cta,
    required this.tag,
    required this.imageUrl,
    required this.colors,
  });

  factory PromoBannerData.fromBanner(BannerModel b) {
    return PromoBannerData(
      title: b.title,
      highlight: b.highlight,
      subtitle: b.subtitle,
      cta: b.cta,
      tag: b.tag,
      imageUrl: b.imageUrl,
      colors: const [Color(0xFF0D3D42), Color(0xFF146B72)],
    );
  }
}

class PromoBanner extends ConsumerStatefulWidget {
  const PromoBanner({super.key});

  @override
  ConsumerState<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends ConsumerState<PromoBanner> {
  final _controller = PageController(viewportFraction: 0.98);
  int _current = 0;
  Timer? _timer;
  int _bannerCount = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients || _bannerCount < 2) return;
      final next = (_current + 1) % _bannerCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(resolvedAppContentProvider);
    final fallback = [
      PromoBannerData(
        title: content.homePromoTitle,
        highlight: content.homeTagline,
        subtitle: content.homePromoSubtitle,
        cta: content.homeCta,
        tag: 'AD',
        imageUrl:
            'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=900',
        colors: const [Color(0xFF0D3D42), Color(0xFF146B72)],
      ),
    ];
    final bannersAsync = ref.watch(activeBannersProvider);
    final banners = bannersAsync.when(
      data: (list) {
        if (list.isEmpty) return fallback;
        return list.map(PromoBannerData.fromBanner).toList();
      },
      loading: () => fallback,
      error: (_, _) => fallback,
    );
    _bannerCount = banners.length;

    return Column(
      children: [
        SizedBox(
          height: BannerModel.sliderHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final active = index == _current;
              return AnimatedScale(
                scale: active ? 1 : 0.96,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: _BannerCard(data: banners[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) {
              final selected = _current == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeInOutCubic,
                width: selected ? 28 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: selected ? AppColors.ctaGradient : null,
                  color: selected ? null : AppColors.border,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.highlight.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBannerData data;

  const _BannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Brand fill behind image (letterbox when aspect doesn't match)
          _FallbackBackdrop(colors: data.colors),

          // Show the full ad image — no cropping
          if (data.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: data.imageUrl,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              width: double.infinity,
              height: double.infinity,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),

          // Light wash so text stays readable without covering the art
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.transparent,
                  data.colors.first.withValues(alpha: 0.35),
                  data.colors.first.withValues(alpha: 0.78),
                ],
                stops: const [0.0, 0.35, 0.72, 1.0],
              ),
            ),
          ),

          // Decorative glow
          Positioned(
            top: -40,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.highlight.withValues(alpha: 0.18),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.highlight,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.8,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.ctaGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.highlight.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.cta,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackBackdrop extends StatelessWidget {
  final List<Color> colors;

  const _FallbackBackdrop({required this.colors});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}
