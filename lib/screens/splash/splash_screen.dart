import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/admin_security.dart';
import '../../core/constants/app_constants.dart';
import '../../core/platform/app_host.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _progress;
  late final AnimationController _shine;
  late final Animation<double> _fade;
  late final Animation<double> _rise;
  late final Animation<double> _scale;
  late final Animation<double> _shineSlide;
  bool _leaving = false;

  static const _brandDeep = Color(0xFF0D3D42);
  static const _brand = Color(0xFF116C71);
  static const _brandMid = Color(0xFF0A555C);

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

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    _rise = Tween<double>(begin: 22, end: 0).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic),
    );
    _shineSlide = Tween<double>(begin: -1.2, end: 1.2).animate(
      CurvedAnimation(parent: _shine, curve: Curves.easeInOutCubic),
    );

    if (AppHost.isWeb) {
      _intro.value = 1;
      _progress.value = 1;
      Future.delayed(const Duration(milliseconds: 400), _goNext);
    } else {
      _intro.forward();
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) _progress.forward();
      });
      Future.delayed(const Duration(milliseconds: 520), () {
        if (mounted) _shine.forward();
      });
      Future.delayed(const Duration(milliseconds: 2400), _goNext);
    }
  }

  Future<void> _goNext() async {
    if (!mounted || _leaving) return;
    setState(() => _leaving = true);
    await Future.delayed(
      Duration(milliseconds: AppHost.isWeb ? 80 : 380),
    );
    if (!mounted) return;

    if (AppHost.isAdminWebConsole) {
      context.go(AdminSecurity.loginPath);
      return;
    }
    // Guests land on the store; signed-in users are redirected by the router.
    context.go('/home');
  }

  @override
  void dispose() {
    _intro.dispose();
    _progress.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandDeep,
      body: AnimatedOpacity(
        opacity: _leaving ? 0 : 1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF155F65),
                    _brand,
                    _brandMid,
                    _brandDeep,
                  ],
                  stops: [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),
            Positioned(
              top: -140,
              right: -90,
              child: IgnorePointer(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -160,
              left: -110,
              child: IgnorePointer(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2A9AA3).withValues(alpha: 0.42),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.sizeOf(context).height * 0.28,
              left: -40,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: AnimatedBuilder(
                animation: Listenable.merge([_intro, _progress, _shine]),
                builder: (context, _) {
                  return Opacity(
                    opacity: _fade.value,
                    child: Transform.translate(
                      offset: Offset(0, _rise.value),
                      child: Column(
                        children: [
                          const Spacer(flex: 5),
                          Transform.scale(
                            scale: _scale.value,
                            child: _GlassLogoMark(shineT: _shineSlide.value),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            AppConstants.appName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: -0.4,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppConstants.appTagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          ),
                          const Spacer(flex: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 96),
                            child: _GlassProgress(value: _progress.value),
                          ),
                          const SizedBox(height: 56),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassLogoMark extends StatelessWidget {
  final double shineT;

  const _GlassLogoMark({required this.shineT});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.16),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.42),
                    width: 1.1,
                  ),
                ),
              ),
              // Soft top rim highlight
              Positioned(
                top: 0,
                left: 18,
                right: 18,
                child: Container(
                  height: 1.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Image.asset(
                    'assets/images/qopcha_app_icon_fg.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              // One-shot glass shine sweep
              IgnorePointer(
                child: Transform.translate(
                  offset: Offset(shineT * 120, shineT * 40),
                  child: Transform.rotate(
                    angle: -0.55,
                    child: Container(
                      width: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.28),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassProgress extends StatelessWidget {
  final double value;

  const _GlassProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 0.6,
            ),
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
