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

  String get headline {
    final h = highlight.trim();
    if (h.isNotEmpty) return h;
    return title.trim();
  }

  String get supporting {
    final s = subtitle.trim();
    if (s.isNotEmpty) return s;
    final t = title.trim();
    if (t.isNotEmpty && t != headline) return t;
    return '';
  }
}

class PromoBanner extends ConsumerStatefulWidget {
  const PromoBanner({super.key});

  @override
  ConsumerState<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends ConsumerState<PromoBanner> {
  PageController? _controller;
  int _current = 0;
  Timer? _timer;
  int _bannerCount = 1;
  double _fraction = 0.86;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: _fraction);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final c = _controller;
      if (c == null || !c.hasClients || _bannerCount < 2) return;
      final next = (_current + 1) % _bannerCount;
      c.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _ensureController(int count) {
    final nextFraction = count <= 1 ? 1.0 : 0.86;
    if (_controller != null &&
        _fraction == nextFraction &&
        _bannerCount == count) {
      return;
    }
    final old = _controller;
    _fraction = nextFraction;
    _bannerCount = count;
    _controller = PageController(
      viewportFraction: _fraction,
      initialPage: _current.clamp(0, count <= 0 ? 0 : count - 1),
    );
    // Dispose previous after the new one is attached next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
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
            'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1200',
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

    _ensureController(banners.length);
    final controller = _controller!;
    final multi = banners.length > 1;

    return Column(
      children: [
        SizedBox(
          height: BannerModel.sliderHeight,
          child: PageView.builder(
            controller: controller,
            itemCount: banners.length,
            padEnds: multi,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final active = index == _current;
              return AnimatedScale(
                scale: multi ? (active ? 1.0 : 0.94) : 1.0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: multi ? 6 : 0,
                    vertical: 4,
                  ),
                  child: _BannerCard(data: banners[index]),
                ),
              );
            },
          ),
        ),
        if (multi) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (i) {
              final selected = _current == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: selected ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: selected
                      ? AppColors.highlight
                      : AppColors.border.withValues(alpha: 0.85),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBannerData data;

  const _BannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final headline = data.headline;
    final supporting = data.supporting;
    final cta = data.cta.trim().isEmpty ? 'Add to Cart' : data.cta.trim();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark ? 0.35 : 0.12,
            ),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.colors,
              ),
            ),
          ),
          if (data.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: data.imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              width: double.infinity,
              height: double.infinity,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0.35, 0.62, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                if (headline.isNotEmpty)
                  Text(
                    headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                      letterSpacing: -0.4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                if (supporting.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    supporting,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _BrutalPillButton(label: cta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrutalPillButton extends StatelessWidget {
  final String label;

  const _BrutalPillButton({required this.label});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
              size: 17,
              color: AppColors.highlight,
            ),
          ],
        ),
      ),
    );
  }
}
