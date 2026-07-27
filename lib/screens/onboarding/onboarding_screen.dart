import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class _OnboardSlide {
  final String imageUrl;
  final String title;
  final String subtitle;
  final bool isAsset;

  const _OnboardSlide({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.isAsset = false,
  });
}

/// Fashion onboarding — cinematic full-bleed slides + soft motion.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const prefsKey = 'onboarding_done';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _enter;
  double _page = 0;
  int _index = 0;

  static final _slides = [
    _OnboardSlide(
      imageUrl: 'assets/images/onboarding_1.png',
      isAsset: true,
      title: 'بەخێربێیت بۆ ${AppConstants.appName}',
      subtitle: 'باشترین جل و بەرگ و مۆدە لە یەک شوێن — بۆ کڕین و فرۆشتن.',
    ),
    const _OnboardSlide(
      imageUrl: 'assets/images/onboarding_2.png',
      isAsset: true,
      title: 'مۆدەی نوێ بدۆزەرەوە',
      subtitle: 'کۆمەڵێک فرۆشگا و ستایلی جیاواز بۆ هەموو تامەزرۆییەک.',
    ),
    const _OnboardSlide(
      imageUrl: 'assets/images/onboarding_3.png',
      isAsset: true,
      title: 'بە ئاسانی بکڕە و بفرۆشە',
      subtitle: 'داواکاری خێرا، فرۆشگای خۆت دروست بکە، و جلەکانت پیشان بدە.',
    ),
  ];

  static const _ease = Cubic(0.22, 1.0, 0.36, 1.0);
  static const _pageDuration = Duration(milliseconds: 680);

  bool get _isLast => _index >= _slides.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onScroll);
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  void _onScroll() {
    if (!_pageController.hasClients) return;
    final p = _pageController.page ?? 0;
    if ((p - _page).abs() > 0.001) {
      setState(() => _page = p);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _enter.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.prefsKey, true);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/auth');
    }
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_isLast) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: _pageDuration, curve: _ease);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final enter = CurvedAnimation(parent: _enter, curve: _ease);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: FadeTransition(
        opacity: enter,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Slides with soft Ken-Burns / parallax
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final delta = (_page - i).clamp(-1.0, 1.0);
                final scale = 1.08 - (delta.abs() * 0.06);
                final opacity = (1.0 - delta.abs() * 0.35).clamp(0.55, 1.0);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: _slides[i].isAsset
                              ? Image.asset(
                                  _slides[i].imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: AppColors.primary,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.checkroom_rounded,
                                      size: 72,
                                      color: Colors.white54,
                                    ),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: _slides[i].imageUrl,
                                  fit: BoxFit.cover,
                                  fadeInDuration:
                                      const Duration(milliseconds: 500),
                                  placeholder: (_, _) => Container(
                                    color: const Color(0xFF141418),
                                  ),
                                  errorWidget: (_, _, _) => Container(
                                    color: AppColors.primary,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.checkroom_rounded,
                                      size: 72,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                        ),
                        // Cinematic vignette + bottom fade
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x33000000),
                                  Colors.transparent,
                                  Color(0x66000000),
                                  Color(0xE6000000),
                                ],
                                stops: [0.0, 0.28, 0.58, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Soft brand mark
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              left: 24,
              right: 24,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(enter),
                child: FadeTransition(
                  opacity: enter,
                  child: Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom copy + controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, bottom > 0 ? 10 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SlideCopy(
                        key: ValueKey(_index),
                        title: _slides[_index].title,
                        subtitle: _slides[_index].subtitle,
                      ),
                      const SizedBox(height: 26),
                      _PageDots(
                        count: _slides.length,
                        index: _index,
                        page: _page,
                        activeColor: AppColors.secondary,
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _finish,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withValues(
                                alpha: 0.92,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                            ),
                            child: const Text(
                              'تێپەڕاندن',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _CtaButton(
                            label: _isLast ? 'دەستپێبکە' : 'دواتر',
                            onPressed: _next,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideCopy extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SlideCopy({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: const Cubic(0.22, 1, 0.36, 1),
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.18,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 15.5,
              fontWeight: FontWeight.w400,
              height: 1.5,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  final double page;
  final Color activeColor;

  const _PageDots({
    required this.count,
    required this.index,
    required this.page,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final dist = (page - i).abs().clamp(0.0, 1.0);
        final width = uiLerp(28, 8, dist);
        final color = Color.lerp(
          activeColor,
          Colors.white.withValues(alpha: 0.75),
          dist,
        )!;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.linear,
          margin: const EdgeInsets.only(right: 8),
          height: 8,
          width: width,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: dist < 0.4
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

double uiLerp(double a, double b, double t) => a + (b - a) * t;

class _CtaButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _CtaButton({required this.label, required this.onPressed});

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        curve: const Cubic(0.4, 0, 0.2, 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 420),
          curve: const Cubic(0.22, 1, 0.36, 1),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: const Cubic(0.22, 1, 0.36, 1),
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              );
            },
            child: Text(
              widget.label,
              key: ValueKey(widget.label),
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
