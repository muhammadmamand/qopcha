import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/sewing_button.dart';
import 'signup_wizard.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final int initialTab;
  final String? nextPath;

  const AuthScreen({super.key, this.initialTab = 0, this.nextPath});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _flipController;
  final _loginFormKey = GlobalKey<FormState>();
  final _loginPhone = TextEditingController();
  final _loginPassword = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscureLoginPass = true;
  int _secretTapCount = 0;
  DateTime? _secretTapAt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    if (widget.initialTab == 1) {
      _flipController.value = 1.0;
    }
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    _phoneFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _flipController.dispose();
    _loginPhone.dispose();
    _loginPassword.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _navigateAfterAuth(UserModel user) {
    // Admin never enters from the public auth screen.
    if (user.isAdmin) {
      _showError(ref.read(stringsProvider).adminCannotLoginHere);
      return;
    }
    if (user.isRejected || (user.isPending && user.isShopOwner)) {
      context.go('/pending');
      return;
    }
    if (user.isShopOwner) {
      context.go('/shop');
      return;
    }
    final next = (widget.nextPath ?? '').trim();
    if (next.isNotEmpty && next.startsWith('/') && !next.startsWith('//')) {
      context.go(next);
      return;
    }
    context.go('/home');
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final success = await ref
        .read(authProvider.notifier)
        .login(_loginPhone.text.trim(), _loginPassword.text);

    if (!mounted) return;

    if (success) {
      final user = ref.read(authProvider).user;
      if (user != null) _navigateAfterAuth(user);
    } else {
      _showError(
        ref.read(authProvider).error ??
            ref.read(stringsProvider).errorGeneric,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        backgroundColor: AppColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _openForgotPassword() async {
    HapticFeedback.selectionClick();
    final phone = _loginPhone.text.trim();
    final uri = phone.isEmpty
        ? '/auth/forgot-password'
        : '/auth/forgot-password?phone=${Uri.encodeComponent(phone)}';
    final sent = await context.push<bool>(uri);
    if (!mounted || sent != true) return;
    _showSuccess(ref.read(stringsProvider).passwordUpdated);
  }

  void _onSecretBrandTap() {
    final now = DateTime.now();
    if (_secretTapAt == null ||
        now.difference(_secretTapAt!) > const Duration(seconds: 3)) {
      _secretTapCount = 0;
    }
    _secretTapAt = now;
    _secretTapCount++;
    if (_secretTapCount >= 7) {
      _secretTapCount = 0;
      HapticFeedback.heavyImpact();
      context.push('/staff-console');
    }
  }

  Future<void> _openSignupWithFlip() async {
    if (_flipController.isAnimating) return;
    if (_flipController.isCompleted) {
      _tabController.animateTo(1);
      return;
    }
    if (_flipController.value > 0) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.mediumImpact();
    await _flipController.forward(from: 0);
    if (!mounted) return;
    _tabController.animateTo(1);
  }

  Future<void> _closeSignupWithFlip() async {
    if (_flipController.isAnimating) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.mediumImpact();
    if (_flipController.value < 1.0) {
      _flipController.value = 1.0;
    }
    _tabController.index = 0;
    setState(() {});
    await _flipController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final lang = ref.watch(appSettingsProvider).language;
    final isLoginTab = _tabController.index == 0;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
      resizeToAvoidBottomInset: true,
        backgroundColor:
            isLoginTab ? Colors.white : const Color(0xFFF7FBFA),
        body: AnimatedSwitcher(
          duration: _flipController.isAnimating
              ? Duration.zero
              : const Duration(milliseconds: 680),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.035),
                  end: Offset.zero,
                ).animate(fade),
                child: child,
              ),
            );
          },
          child: isLoginTab
              ? KeyedSubtree(
                  key: const ValueKey('login'),
                  child: _buildLoginTab(
                    isLoading: authState.isLoading,
                    language: lang,
                    keyboardOpen: keyboardOpen,
                  ),
                )
              : KeyedSubtree(
                  key: const ValueKey('signup'),
                  child: _buildSignupTab(language: lang),
                ),
        ),
      ),
    );
  }

  InputDecoration _loginFieldDecoration({
    required String hint,
    Widget? suffix,
    required bool focused,
  }) {
    final line = focused ? Colors.white : Colors.white.withValues(alpha: 0.45);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: Colors.white.withValues(alpha: 0.42),
        fontWeight: FontWeight.w500,
        fontSize: 14.5,
      ),
      suffixIcon: suffix,
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: UnderlineInputBorder(borderSide: BorderSide(color: line)),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 1.6),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFF8A80)),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFF8A80), width: 1.4),
      ),
      errorStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: const Color(0xFFFF8A80),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }

  Widget _buildSignupTab({required AppLanguage language}) {
    return SignupWizard(
      language: language,
      onBack: _closeSignupWithFlip,
      onSuccess: () {
        final user = ref.read(authProvider).user;
        if (user != null) {
          _navigateAfterAuth(user);
        }
      },
    );
  }

  Widget _buildLoginTab({
    required bool isLoading,
    required AppLanguage language,
    required bool keyboardOpen,
  }) {
    final topPad = keyboardOpen ? 16.0 : 32.0;
    const bottomPad = 20.0;
    final screen = MediaQuery.sizeOf(context);
    final btnSize = keyboardOpen ? 88.0 : 112.0;
    final peakTop = screen.height * _LoginArtPainter.peakYFactor;

    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, _) {
        final openT = Curves.easeInBack.transform(
          (_flipController.value / 0.34).clamp(0.0, 1.0),
        );
        final flipT = Curves.easeInOutBack.transform(
          ((_flipController.value - 0.26) / 0.74).clamp(0.0, 1.0),
        );

        return Stack(
              children: [
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + 6,
              end: 16,
              child: const LanguageSwitcherButton(),
            ),
            SafeArea(
                  child: Padding(
                padding: EdgeInsets.fromLTRB(28, topPad, 28, 0),
                    child: Column(
                      children: [
                    _buildLoginBrandHeader(),
                        if (!keyboardOpen) ...[
                      const SizedBox(height: 36),
                      const _LoginFashionPicks(),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              top: peakTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: Transform(
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.00115)
                  // Reverse the pocket fold on signup (opposite of before).
                  ..rotateX(flipT * math.pi),
                child: Opacity(
                  opacity: (1 - flipT).clamp(0.0, 1.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ClipPath(
                          clipper: const _LoginPeakClipper(),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const ColoredBox(color: Color(0xFF116C71)),
                              ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF116C71),
                                  BlendMode.color,
                                ),
                                child: Opacity(
                                  opacity: 0.55,
                              child: Image.asset(
                                    'assets/images/login_panel_texture.png',
                                    fit: BoxFit.cover,
                                    alignment: Alignment.bottomRight,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _LoginStitchPainter(
                              buttonClearance: btnSize * 0.46,
                              seamProgress: flipT,
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                32,
                                keyboardOpen ? 28 : 56,
                                32,
                                bottomPad,
                              ),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight:
                                      (constraints.maxHeight -
                                              (keyboardOpen ? 28 : 56) -
                                              bottomPad)
                                          .clamp(0.0, double.infinity),
                                ),
                                child: Form(
                                  key: _loginFormKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                            children: [
                                      const SizedBox.shrink(),
                                      _buildLoginFields(
                                        isLoading: isLoading,
                                        language: language,
                                      ),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                              Text(
                                            tr(
                                              language,
                                              'هەژمارت نییە؟ ',
                                              "Don't have account? ",
                                              'ليس لديك حساب؟ ',
                                            ),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white.withValues(
                                                alpha: 0.88,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: isLoading
                                                ? null
                                                : _openSignupWithFlip,
                                            child: Text(
                                              tr(
                                                language,
                                                'تۆمارکردن',
                                                'Register now',
                                                'سجّل الآن',
                                              ),
                                              style: TextStyle(
                                                fontFamily:
                                                    AppTheme.fontFamily,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                    ),
                  ),
                ),
                                        ],
                              ),
                            ],
                          ),
                                ),
                              ),
                            );
                          },
                        ),
                                    ),
                                  ],
                                ),
                              ),
              ),
            ),
            Positioned(
              top: peakTop - btnSize / 2 + 12,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: (1 - openT).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(18 * openT, -100 * openT),
                    child: Transform.rotate(
                      angle: openT * 2.35,
                      child: Transform.scale(
                        scale: 1 + 0.12 * openT,
                        child: Center(
                          child: SewingButton(size: btnSize),
                      ),
                    ),
                  ),
                ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginFields({
    required bool isLoading,
    required AppLanguage language,
  }) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        _loginFieldLabel(tr(language, 'ژمارەی مۆبایل', 'Phone number', 'رقم الهاتف')),
            TextFormField(
          controller: _loginPhone,
          focusNode: _phoneFocus,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          style: _loginInputStyle,
              textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          cursorColor: Colors.white,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
          validator: (v) => PhoneUtils.validate(v, language: language),
          decoration: _loginFieldDecoration(
            hint: '07xxxxxxxxx',
            focused: _phoneFocus.hasFocus,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _loginFieldLabel(
                tr(language, 'وشەی نهێنی', 'Password', 'كلمة المرور'),
              ),
            ),
            GestureDetector(
              onTap: isLoading ? null : _openForgotPassword,
              child: Text(
                tr(language, 'لەبیرچووە؟', 'Forgot?', 'نسيت؟'),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
            TextFormField(
              controller: _loginPassword,
              focusNode: _passwordFocus,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          style: _loginInputStyle,
              textInputAction: TextInputAction.done,
              obscureText: _obscureLoginPass,
          cursorColor: Colors.white,
              onFieldSubmitted: (_) => _handleLogin(),
          validator: (v) => v == null || v.length < 4
              ? tr(language, 'وشەی نهێنی بنووسە', 'Enter your password',
                  'أدخل كلمة المرور')
              : null,
          decoration: _loginFieldDecoration(
            hint: '********',
            focused: _passwordFocus.hasFocus,
            suffix: IconButton(
                  onPressed: () => setState(
                    () => _obscureLoginPass = !_obscureLoginPass,
                  ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              visualDensity: VisualDensity.compact,
                  icon: Icon(
                    _obscureLoginPass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
            SizedBox(
              height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.highlight,
                    foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.highlight.withValues(alpha: 0.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                    tr(language, 'چوونەژوورەوە', 'Login', 'تسجيل الدخول'),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 10),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                  HapticFeedback.selectionClick();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                  child: Text(
            tr(language, 'بەردەوامبە وەک میوان', 'Continue as guest',
                'المتابعة كضيف'),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13.5,
                    ),
                  ),
                ),
      ],
    );
  }

  Widget _buildLoginBrandHeader() {
    return GestureDetector(
      onTap: _onSecretBrandTap,
      onLongPress: () {
        HapticFeedback.heavyImpact();
        context.push('/staff-console');
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF116C71),
                BlendMode.srcIn,
              ),
              child: Image.asset('assets/images/qopcha_logo.png'),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            AppConstants.appName,
            style: TextStyle(
          fontFamily: AppTheme.fontFamily,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.brand,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
              child: Text(
        text,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
          fontSize: 12.5,
              fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      ),
    );
  }

  TextStyle get _loginInputStyle => const TextStyle(
                fontFamily: AppTheme.fontFamily,
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 15.5,
      );
}

class _LoginFashionPicks extends StatefulWidget {
  const _LoginFashionPicks();

  static const _assets = [
    'assets/images/category/t_shirt.png',
    'assets/images/category/shirt.png',
    'assets/images/category/shoes.png',
    'assets/images/category/cap.png',
    'assets/images/category/bag.png',
    'assets/images/category/formal.png',
    'assets/images/category/sports.png',
  ];

  @override
  State<_LoginFashionPicks> createState() => _LoginFashionPicksState();
}

class _LoginFashionPicksState extends State<_LoginFashionPicks>
    with SingleTickerProviderStateMixin {
  static const _iconSize = 38.0;
  static const _gap = 28.0;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _strip() {
    return Row(
      mainAxisSize: MainAxisSize.min,
            children: [
        for (final asset in _LoginFashionPicks._assets)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                AppColors.brand,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                asset,
                width: _iconSize,
                height: _iconSize,
                fit: BoxFit.contain,
              ),
                      ),
                    ),
                  ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stripWidth =
        (_iconSize + _gap) * _LoginFashionPicks._assets.length;

    return SizedBox(
      height: _iconSize,
      width: double.infinity,
      child: ClipRect(
        child: IgnorePointer(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final loopWidth = stripWidth * 2;
                final boxWidth = math.max(loopWidth, constraints.maxWidth);
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final dx = _controller.value * stripWidth;
                    return OverflowBox(
                      minWidth: 0,
                      maxWidth: boxWidth,
                      minHeight: 0,
                      maxHeight: _iconSize,
                      alignment: Alignment.centerLeft,
                      child: Transform.translate(
                        offset: Offset(-dx, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _strip(),
                            _strip(),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginArtPainter extends CustomPainter {
  const _LoginArtPainter({
    required this.top,
    this.layer = _LoginArtLayer.all,
  });

  final Color top;
  final _LoginArtLayer layer;
  static const _bottom = Color(0xFF116C71);
  static const peakYFactor = 0.30;

  static Path peakPath(Size size, {_LoginArtLayer layer = _LoginArtLayer.bottom}) {
    final w = size.width;
    final h = size.height;
    final leftY = layer == _LoginArtLayer.bottom ? h * 0.257 : h * 0.48;
    final peakY = layer == _LoginArtLayer.bottom ? 0.0 : h * peakYFactor;
    final tip = w * 0.07;
    final slope = (leftY - peakY) / (w * 0.5);
    final joinY = peakY + slope * tip;

    return Path()
      ..moveTo(0, h)
      ..lineTo(0, leftY)
      ..lineTo(w * 0.5 - tip, joinY)
      ..quadraticBezierTo(w * 0.5, peakY, w * 0.5 + tip, joinY)
      ..lineTo(w, leftY)
      ..lineTo(w, h)
      ..close();
  }

  /// The two roof slopes only — the red-outlined sewing path.
  static Path topSeamPath(
    Size size, {
    _LoginArtLayer layer = _LoginArtLayer.bottom,
  }) {
    final w = size.width;
    final h = size.height;
    final leftY = layer == _LoginArtLayer.bottom ? h * 0.257 : h * 0.48;
    final peakY = layer == _LoginArtLayer.bottom ? 0.0 : h * peakYFactor;
    final tip = w * 0.07;
    final slope = (leftY - peakY) / (w * 0.5);
    final joinY = peakY + slope * tip;

    return Path()
      ..moveTo(0, leftY)
      ..lineTo(w * 0.5 - tip, joinY)
      ..quadraticBezierTo(w * 0.5, peakY, w * 0.5 + tip, joinY)
      ..lineTo(w, leftY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (layer != _LoginArtLayer.bottom) {
      canvas.drawRect(Offset.zero & size, Paint()..color = top);
    }

    if (layer == _LoginArtLayer.top) return;

    canvas.drawPath(peakPath(size, layer: layer), Paint()..color = _bottom);
  }

  @override
  bool shouldRepaint(covariant _LoginArtPainter oldDelegate) =>
      oldDelegate.top != top || oldDelegate.layer != layer;
}

class _LoginPeakClipper extends CustomClipper<Path> {
  const _LoginPeakClipper();

  @override
  Path getClip(Size size) => _LoginArtPainter.peakPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LoginStitchPainter extends CustomPainter {
  const _LoginStitchPainter({
    required this.buttonClearance,
    this.seamProgress = 0,
  });

  final double buttonClearance;
  final double seamProgress;

  static Path? _inset(Path source, double distance) {
    final out = Path();
    var started = false;
    for (final metric in source.computeMetrics()) {
      const step = 2.0;
      for (double d = 0; d <= metric.length; d += step) {
        final tangent = metric.getTangentForOffset(d.clamp(0, metric.length));
        if (tangent == null) continue;
        final n = Offset(-tangent.vector.dy, tangent.vector.dx);
        final len = n.distance;
        if (len < 0.001) continue;
        final p = tangent.position + n * (distance / len);
        if (!started) {
          out.moveTo(p.dx, p.dy);
          started = true;
        } else {
          out.lineTo(p.dx, p.dy);
        }
      }
    }
    return started ? out : null;
  }

  static void _dash(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dash,
    required double gap,
    required double skipCenter,
  }) {
    for (final metric in path.computeMetrics()) {
      final mid = metric.length / 2;
      var d = 0.0;
      var drawing = true;
      while (d < metric.length) {
        final span = drawing ? dash : gap;
        final end = (d + span).clamp(0.0, metric.length);
        if (drawing) {
          final center = (d + end) / 2;
          final underButton =
              (center - mid).abs() < skipCenter;
          if (!underButton && end > d) {
            canvas.drawPath(metric.extractPath(d, end), paint);
          }
        }
        d = end;
        drawing = !drawing;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final seam = _LoginArtPainter.topSeamPath(size);
    final outer = _inset(seam, 10);
    final inner = _inset(seam, 16);
    if (outer == null) return;

    if (seamProgress > 0.02) {
      _drawSeamHighlight(canvas, outer, seamProgress);
    }

    final thread = Paint()
      ..color = const Color(0xF2F7F3EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    _dash(
      canvas,
      outer,
      thread,
      dash: 7.2,
      gap: 5.4,
      skipCenter: buttonClearance,
    );

    if (inner != null) {
      thread.strokeWidth = 1.45;
      thread.color = const Color(0xD9F7F3EC);
      _dash(
        canvas,
        inner,
        thread,
        dash: 6.4,
        gap: 6.0,
        skipCenter: buttonClearance + 4,
      );
    }
  }

  void _drawSeamHighlight(Canvas canvas, Path seam, double progress) {
    final t = progress.clamp(0.0, 1.0);
    for (final metric in seam.computeMetrics()) {
      final end = metric.length * t;
      if (end <= 0.5) continue;
      final segment = metric.extractPath(0, end);

      final glow = Paint()
        ..color = AppColors.highlight.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(segment, glow);

      final thread = Paint()
        ..color = AppColors.highlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(segment, thread);
    }
  }

  @override
  bool shouldRepaint(covariant _LoginStitchPainter oldDelegate) =>
      oldDelegate.buttonClearance != buttonClearance ||
      oldDelegate.seamProgress != seamProgress;
}

enum _LoginArtLayer { top, bottom, all }

