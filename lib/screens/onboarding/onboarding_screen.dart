import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const prefsKey = 'onboarding_done';
  static const languagePickedKey = 'welcome_language_picked';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const _deep = Color(0xFF062326);
  static const _mist = Color(0xFFF4F7F7);

  bool _showLanguage = true;
  bool _ready = false;
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final picked = prefs.getBool(OnboardingScreen.languagePickedKey) ?? false;
    if (!mounted) return;
    setState(() {
      _showLanguage = !picked;
      _ready = true;
    });
  }

  Future<void> _pickLanguage(AppLanguage language) async {
    HapticFeedback.selectionClick();
    await ref.read(appSettingsProvider.notifier).setLanguage(language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.languagePickedKey, true);
    if (!mounted) return;
    setState(() => _showLanguage = false);
  }

  Future<void> _continue({required bool signup}) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.prefsKey, true);
    if (!mounted) return;
    context.go(signup ? '/auth?tab=signup' : '/auth?tab=login');
  }

  bool get _english =>
      ref.watch(appSettingsProvider).language == AppLanguage.english;

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: _deep,
        body: SizedBox.expand(),
      );
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    final selected = ref.watch(appSettingsProvider).language;

    return Scaffold(
      backgroundColor: _mist,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Atmosphere(controller: _ambient),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _BrandMark(english: _english)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.12, curve: Curves.easeOutCubic),
                Expanded(
                  child: const _HeroStage()
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 700.ms)
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        curve: Curves.easeOutCubic,
                      ),
                ),
                _BottomPanel(
                  english: _english,
                  bottomInset: bottom,
                  onStart: () => _continue(signup: true),
                  onLogin: () => _continue(signup: false),
                )
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 500.ms)
                    .slideY(begin: 0.08, curve: Curves.easeOutCubic),
              ],
            ),
          ),
          if (_showLanguage)
            _LanguageSheet(
              selected: selected,
              onPick: _pickLanguage,
            ),
        ],
      ),
    );
  }
}

class _Atmosphere extends StatelessWidget {
  final AnimationController controller;

  const _Atmosphere({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF062326),
                    Color(0xFF0B3C40),
                    Color(0xFF116C71),
                    Color(0xFFE8F1F1),
                    Color(0xFFF7FAFA),
                  ],
                  stops: [0.0, 0.22, 0.42, 0.62, 1.0],
                ),
              ),
            ),
            Positioned(
              top: -80 + (t * 24),
              right: -90,
              child: _GlowOrb(
                size: 280,
                color: const Color(0xFFF15C22).withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              top: 120 - (t * 18),
              left: -110,
              child: _GlowOrb(
                size: 260,
                color: const Color(0xFF2A9AA3).withValues(alpha: 0.28),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final bool english;

  const _BrandMark({required this.english});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/qopcha_logo.png',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                english ? AppConstants.appNameEn : AppConstants.appName,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStage extends StatelessWidget {
  const _HeroStage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 220,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Image.asset(
            'assets/images/login_hero.png',
            fit: BoxFit.contain,
          ),
          Positioned(
            top: 12,
            right: 18,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final bool english;
  final double bottomInset;
  final VoidCallback onStart;
  final VoidCallback onLogin;

  const _BottomPanel({
    required this.english,
    required this.bottomInset,
    required this.onStart,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 28, 24, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE6E7),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            english ? 'KURDISTAN FASHION' : 'مۆدەی کوردستان',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: const Color(0xFF116C71),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            english
                ? 'Fashion, done for you.\nAnytime, anywhere.'
                : 'جل و بەرگ، بۆ تۆ.\nهەر کاتێک، هەر شوێنێک.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F0F14),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            english
                ? 'Shop independent labels, discover new drops, and sell with a studio-grade storefront.'
                : 'باشترین فرۆشگا و ستایل بدۆزەرەوە — کڕین و فرۆشتن لە یەک شوێنی سادەدا.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5A6A6C),
            ),
          ),
          const SizedBox(height: 26),
          _PrimaryCta(
            label: english ? 'Get Started' : 'دەستپێبکە',
            onTap: onStart,
          ),
          const SizedBox(height: 10),
          _GhostCta(
            label: english ? 'I already have an account' : 'هەژمارم هەیە',
            onTap: onLogin,
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11,
                height: 1.45,
                color: const Color(0xFF8A9A9C),
              ),
              children: [
                TextSpan(
                  text: english
                      ? 'By continuing you agree to our '
                      : 'بەردەوامبوون واتە ڕەزامەندی لەسەر ',
                ),
                TextSpan(
                  text: english ? 'Terms' : 'مەرجەکان',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A6A6C),
                  ),
                ),
                TextSpan(text: english ? ' and ' : ' و '),
                TextSpan(
                  text: english ? 'Privacy Policy' : 'تایبەتمەندی',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A6A6C),
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF178087), Color(0xFF0D3D42)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF116C71).withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _GhostCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GhostCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F0F14),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDCE6E7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onPick;

  const _LanguageSheet({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: const ColoredBox(color: Color(0x73000000)),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              22,
              16,
              22,
              22 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE6E7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'LANGUAGE',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: const Color(0xFF116C71),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your language',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F0F14),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You can change this later in Settings.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    color: const Color(0xFF8A9A9C),
                  ),
                ),
                const SizedBox(height: 22),
                _LanguageCard(
                  native: 'English',
                  latin: 'United States',
                  code: 'EN',
                  selected: selected == AppLanguage.english,
                  onTap: () => onPick(AppLanguage.english),
                ),
                const SizedBox(height: 10),
                _LanguageCard(
                  native: 'کوردی',
                  latin: 'Kurdish · Sorani',
                  code: 'KU',
                  selected: selected == AppLanguage.kurdish,
                  onTap: () => onPick(AppLanguage.kurdish),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 280.ms);
  }
}

class _LanguageCard extends StatelessWidget {
  final String native;
  final String latin;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.native,
    required this.latin,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEFF8F8) : const Color(0xFFF7FAFA),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFF116C71)
                  : const Color(0xFFDCE6E7),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF116C71) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: selected ? Colors.white : const Color(0xFF116C71),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      native,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F0F14),
                      ),
                    ),
                    Text(
                      latin,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5,
                        color: const Color(0xFF8A9A9C),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected
                    ? const Color(0xFF116C71)
                    : const Color(0xFFDCE6E7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
