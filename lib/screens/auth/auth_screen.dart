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
  bool _loginBusy = false;
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
      if (!mounted || _tabController.indexIsChanging) return;
      setState(() {});
    });
    // Do NOT setState on focus changes — on MIUI/Redmi that rebuilds the
    // TextFormField and instantly closes the keyboard.
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
    if (_loginBusy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    HapticFeedback.lightImpact();
    setState(() => _loginBusy = true);

    final success = await ref
        .read(authProvider.notifier)
        .login(_loginPhone.text.trim(), _loginPassword.text);

    if (!mounted) return;
    setState(() => _loginBusy = false);

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
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.mediumImpact();
    _flipController.value = 1.0;
    if (!mounted) return;
    _tabController.animateTo(1);
  }

  Future<void> _closeSignupWithFlip() async {
    if (_flipController.isAnimating) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.mediumImpact();
    _tabController.index = 0;
    setState(() {});
    _flipController.value = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    final lang = ref.watch(appSettingsProvider).language;
    final isLoginTab = _tabController.index == 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        // MIUI/Redmi needs real adjustResize — never disable this on login.
        resizeToAvoidBottomInset: true,
        backgroundColor:
            isLoginTab ? const Color(0xFFF3F8F8) : const Color(0xFFF7FBFA),
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
                    isLoading: _loginBusy,
                    language: lang,
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
  }) {
    final fill = Colors.white.withValues(alpha: 0.14);
    final line = Colors.white.withValues(alpha: 0.20);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: Colors.white.withValues(alpha: 0.42),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: fill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF8A80)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.4),
      ),
      errorStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: const Color(0xFFFF8A80),
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
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

  Widget _buildLoginRegisterRow({
    required AppLanguage language,
    required bool isLoading,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.86),
          ),
        ),
        GestureDetector(
          onTap: isLoading ? null : _openSignupWithFlip,
          child: Text(
            tr(language, 'تۆمارکردن', 'Register now', 'سجّل الآن'),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.highlight,
            ),
          ),
        ),
      ],
    );
  }

  /// Fresh atelier-style login: light stage + teal card + sewing badge.
  /// Keyboard-safe and iPad-safe: scrollable, opaque Login hit target.
  Widget _buildLoginTab({
    required bool isLoading,
    required AppLanguage language,
  }) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.shortestSide >= 600;
    final formMaxWidth = isTablet ? 480.0 : double.infinity;
    final formHeight = keyboardOpen || isTablet ? null : size.height * 0.62;

    return ColoredBox(
      color: const Color(0xFFF3F8F8),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brand.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -70,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.highlight.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(bottom: bottomSafe),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - bottomSafe,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: Row(
                            children: [
                              const LanguageSwitcherButton(),
                              const Spacer(),
                            ],
                          ),
                        ),
                        if (!keyboardOpen) ...[
                          const SizedBox(height: 6),
                          _buildLoginBrandHeader(),
                          const SizedBox(height: 6),
                          Text(
                            tr(
                              language,
                              'بازاڕی جل و بەرگی عێراق',
                              'Iraq clothing marketplace',
                              'سوق الملابس في العراق',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brand.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: _LoginFashionPicks(),
                          ),
                          const SizedBox(height: 8),
                        ] else
                          const SizedBox(height: 8),
                        if (!isTablet) const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: formMaxWidth),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 24 : 0,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.topCenter,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: formHeight,
                                    margin: EdgeInsets.only(
                                      top: keyboardOpen ? 0 : 28,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.vertical(
                                        top: const Radius.circular(28),
                                        bottom: Radius.circular(
                                          isTablet ? 28 : 0,
                                        ),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.gradientStart,
                                          AppColors.brand,
                                          const Color(0xFF0A5A5F),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.gradientStart
                                              .withValues(alpha: 0.35),
                                          blurRadius: 28,
                                          offset: const Offset(0, 14),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                        top: const Radius.circular(28),
                                        bottom: Radius.circular(
                                          isTablet ? 28 : 0,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: IgnorePointer(
                                              child: CustomPaint(
                                                painter:
                                                    _LoginFormSewingBorderPainter(
                                                  inset: 11,
                                                  radius: 22,
                                                  buttonGap:
                                                      keyboardOpen ? 0 : 78,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              22,
                                              keyboardOpen ? 18 : 44,
                                              22,
                                              18,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  tr(
                                                    language,
                                                    'چوونەژوورەوە',
                                                    'Sign in',
                                                    'تسجيل الدخول',
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppTheme.fontFamily,
                                                    fontSize: keyboardOpen
                                                        ? 20
                                                        : 24,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                    height: 1.1,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height:
                                                      keyboardOpen ? 14 : 20,
                                                ),
                                                Form(
                                                  key: _loginFormKey,
                                                  child: _buildLoginFields(
                                                    isLoading: isLoading,
                                                    language: language,
                                                    compact: true,
                                                    showGuest: false,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height:
                                                      keyboardOpen ? 10 : 16,
                                                ),
                                                _buildLoginFieldsGuest(
                                                  isLoading: isLoading,
                                                  language: language,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildLoginRegisterRow(
                                                  language: language,
                                                  isLoading: isLoading,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!keyboardOpen)
                                    const Positioned(
                                      top: 0,
                                      child: IgnorePointer(
                                        child: SewingButton(size: 64),
                                      ),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginFieldsGuest({
    required bool isLoading,
    required AppLanguage language,
  }) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
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
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildLoginFields({
    required bool isLoading,
    required AppLanguage language,
    bool compact = false,
    bool showGuest = true,
  }) {
    final gap = compact ? 10.0 : 14.0;
    final beforeBtn = compact ? 14.0 : 18.0;
    const scrollPad = EdgeInsets.only(bottom: 100);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _loginFieldLabel(
          tr(language, 'ژمارەی مۆبایل', 'Phone number', 'رقم الهاتف'),
        ),
        TextFormField(
          key: const ValueKey('login_phone'),
          controller: _loginPhone,
          focusNode: _phoneFocus,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          style: _loginInputStyle,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          cursorColor: Colors.white,
          scrollPadding: scrollPad,
          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
          validator: (v) => PhoneUtils.validate(v, language: language),
          decoration: _loginFieldDecoration(hint: '07xxxxxxxxx'),
        ),
        SizedBox(height: gap),
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
                  fontWeight: FontWeight.w700,
                  color: AppColors.highlight,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        TextFormField(
          key: const ValueKey('login_password'),
          controller: _loginPassword,
          focusNode: _passwordFocus,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          style: _loginInputStyle,
          textInputAction: TextInputAction.done,
          obscureText: _obscureLoginPass,
          cursorColor: Colors.white,
          scrollPadding: scrollPad,
          onFieldSubmitted: (_) => _handleLogin(),
          validator: (v) => v == null || v.length < 4
              ? tr(language, 'وشەی نهێنی بنووسە', 'Enter your password',
                  'أدخل كلمة المرور')
              : null,
          decoration: _loginFieldDecoration(
            hint: '********',
            suffix: IconButton(
              onPressed: () => setState(
                () => _obscureLoginPass = !_obscureLoginPass,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                _obscureLoginPass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: 18,
              ),
            ),
          ),
        ),
        SizedBox(height: beforeBtn),
        _LoginCtaButton(
          loading: isLoading,
          label: tr(language, 'چوونەژوورەوە', 'Login', 'تسجيل الدخول'),
          onPressed: isLoading ? null : _handleLogin,
        ),
        if (showGuest) ...[
          const SizedBox(height: 4),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
        ],
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
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF116C71),
                BlendMode.srcIn,
              ),
              child: Image.asset('assets/images/qopcha_logo.png'),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppConstants.appName,
            style: TextStyle(
          fontFamily: AppTheme.fontFamily,
              fontSize: 28,
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
      padding: const EdgeInsets.only(bottom: 4),
              child: Text(
        text,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
          fontSize: 12,
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
        fontSize: 14.5,
      );
}

class _LoginCtaButton extends StatelessWidget {
  const _LoginCtaButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: MouseRegion(
        cursor: onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Container(
            height: 52,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.highlight.withValues(alpha: 0.38),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
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

/// Dashed sewing stitch around the login form card.
class _LoginFormSewingBorderPainter extends CustomPainter {
  const _LoginFormSewingBorderPainter({
    required this.inset,
    required this.radius,
    this.buttonGap = 0,
  });

  final double inset;
  final double radius;
  final double buttonGap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
      bottomLeft: Radius.circular(radius * 0.35),
      bottomRight: Radius.circular(radius * 0.35),
    );

    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const dash = 5.5;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        if (buttonGap > 0) {
          final t = metric.getTangentForOffset(distance);
          if (t != null) {
            final onTop = (t.position.dy - inset).abs() < 3;
            final cx = size.width / 2;
            if (onTop && (t.position.dx - cx).abs() < buttonGap / 2) {
              distance += gap;
              continue;
            }
          }
        }
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoginFormSewingBorderPainter oldDelegate) =>
      oldDelegate.inset != inset ||
      oldDelegate.radius != radius ||
      oldDelegate.buttonGap != buttonGap;
}
