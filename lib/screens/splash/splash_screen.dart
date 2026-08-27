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
  late final Animation<double> _fade;
  late final Animation<double> _rise;
  late final Animation<double> _scale;
  bool _leaving = false;

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

    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    _rise = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C3D42),
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
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF15575C),
                    Color(0xFF0F4A4F),
                    Color(0xFF0A3338),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -120,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: IgnorePointer(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brand.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: AnimatedBuilder(
                animation: Listenable.merge([_intro, _progress]),
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
                            child: Container(
                              width: 88,
                              height: 88,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/qopcha_logo.png',
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            AppConstants.appName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppConstants.appTagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          ),
                          const Spacer(flex: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 88),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: SizedBox(
                                height: 3,
                                child: LinearProgressIndicator(
                                  value: _progress.value,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.16),
                                  color: Colors.white,
                                  minHeight: 3,
                                ),
                              ),
                            ),
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
