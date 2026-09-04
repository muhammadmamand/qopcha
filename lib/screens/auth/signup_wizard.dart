import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/settings/legal_document_screen.dart';
import '../../widgets/language_switcher.dart';

/// Single-page signup — polished boutique look.
class SignupWizard extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final AppLanguage language;
  final VoidCallback? onBack;

  const SignupWizard({
    super.key,
    this.onSuccess,
    this.language = AppLanguage.kurdish,
    this.onBack,
  });

  @override
  ConsumerState<SignupWizard> createState() => _SignupWizardState();
}

class _SignupWizardState extends ConsumerState<SignupWizard> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _shopName = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _shopFocus = FocusNode();

  UserRole _role = UserRole.customer;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  String? _termsError;
  bool _otpSending = false;
  int _otpCooldownSecs = 0;
  Timer? _otpCooldownTimer;

  AppLanguage get _lang => widget.language;
  String _t(String ku, String en, [String? ar]) =>
      tr(_lang, ku, en, ar ?? ku);

  static const _inputTextStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    color: Color(0xFF152426),
    fontWeight: FontWeight.w600,
    fontSize: 15,
  );

  @override
  void initState() {
    super.initState();
    for (final n in [
      _nameFocus,
      _phoneFocus,
      _otpFocus,
      _passFocus,
      _confirmFocus,
      _shopFocus,
    ]) {
      n.addListener(() => setState(() {}));
    }
    _otp.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _otpCooldownTimer?.cancel();
    _name.dispose();
    _phone.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    _shopName.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    _shopFocus.dispose();
    super.dispose();
  }

  Future<void> _sendSignupOtp() async {
    final phoneError = PhoneUtils.validate(_phone.text, language: _lang);
    if (phoneError != null) {
      _showSnack(phoneError, error: true);
      return;
    }
    if (_otpCooldownSecs > 0 || _otpSending) return;

    HapticFeedback.selectionClick();
    setState(() => _otpSending = true);
    final error =
        await ref.read(authProvider.notifier).sendSignupOtp(_phone.text.trim());
    if (!mounted) return;
    setState(() => _otpSending = false);

    if (error != null) {
      _showSnack(error, error: true);
      return;
    }

    _otpCooldownTimer?.cancel();
    setState(() => _otpCooldownSecs = 45);
    _otpCooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_otpCooldownSecs <= 1) {
        t.cancel();
        setState(() => _otpCooldownSecs = 0);
        } else {
        setState(() => _otpCooldownSecs -= 1);
      }
    });
    _otpFocus.requestFocus();
    _showSnack(
      _t(
        'کۆد نێردرا (واتساپ یان SMS) — کۆدی ٦ ژمارەیی بنووسە',
        'Code sent (WhatsApp or SMS) — enter the 6-digit code',
        'تم إرسال الرمز (واتساب أو SMS) — أدخل الرمز المكون من 6 أرقام',
      ),
    );
  }

  void _showSnack(String message, {bool error = false}) {
        ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.brand,
            behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _termsError = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() {
        _termsError = _t(
          'تکایە مەرج و سیاسەت قبوڵ بکە',
          'Please accept the terms',
          'يرجى قبول الشروط وسياسة الخصوصية',
        );
      });
        return;
    }

    HapticFeedback.lightImpact();
    final success = await ref.read(authProvider.notifier).register(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
          code: _otp.text.trim(),
          role: _role,
          shopName:
              _role == UserRole.shopOwner ? _shopName.text.trim() : null,
          shopTier: _role == UserRole.shopOwner ? ShopTier.gold : null,
        );

    if (!mounted) return;
    if (success) {
      widget.onSuccess?.call();
    } else {
      _showSnack(
        ref.read(authProvider).error ??
            _t('هەڵەیەک ڕوویدا', 'Something went wrong', 'حدث خطأ ما'),
        error: true,
      );
    }
  }

  InputDecoration _field({
    required String hint,
    required IconData icon,
    required bool focused,
    Widget? suffix,
    bool valid = false,
  }) {
    const radius = BorderRadius.all(Radius.circular(22));
    final borderColor = valid
        ? AppColors.success
        : focused
            ? AppColors.brand
            : const Color(0xFFE2EBEC);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: const Color(0xFFA0AEB0),
        fontWeight: FontWeight.w500,
        fontSize: 14.5,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) {
            return ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            );
          },
          child: valid
              ? Icon(
                  Icons.check_circle_rounded,
                  key: const ValueKey('phone-ok'),
                  color: AppColors.success,
                  size: 24,
                )
              : Icon(
                  icon,
                  key: ValueKey(icon.codePoint),
                  color: focused
                      ? AppColors.brand
                      : AppColors.brand.withValues(alpha: 0.85),
                  size: 22,
                ),
        ),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor.withValues(alpha: 0.95)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: valid ? AppColors.success : AppColors.brand,
          width: 1.6,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.error, width: 1.4),
      ),
      errorStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }

  Widget _softField({required Widget child, required bool focused}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: focused
                ? AppColors.brand.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.045),
            blurRadius: focused ? 18 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFC),
      body: Stack(
        children: [
          const _SignupBackdrop(),
          SafeArea(
            child: Column(
      children: [
        Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 6,
                    end: 14,
                    top: 2,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.brand,
                          backgroundColor: Colors.white.withValues(alpha: 0.75),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                        ),
                      ),
                      const Spacer(),
                      const LanguageSwitcherButton(),
                    ],
                  ),
                ),
        Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(26, 0, 26, 28 + bottom),
                      physics: const BouncingScrollPhysics(),
            children: [
                        _SignupHeroHeader(language: _lang)
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                        const SizedBox(height: 18),
                        Text(
                          _t('هەژمارێکی نوێ دروست بکە', 'Create a new account',
                              'إنشاء حساب جديد'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w900,
                            fontSize: 25,
                            color: const Color(0xFF152426),
                            height: 1.25,
                            letterSpacing: -0.3,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 80.ms, duration: 420.ms)
                            .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                        const SizedBox(height: 8),
                        Text(
                          _t(
                            'بۆ ئەوەی باشترین جل و بەرگەکان ببینیتەوە',
                            'So you can discover the best clothes',
                            'لتكتشف أفضل الملابس',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5,
                            color: const Color(0xFF7E8E90),
                            height: 1.45,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 120.ms, duration: 420.ms),
                        const SizedBox(height: 20),
                        _RoleToggle(
                  role: _role,
                          language: _lang,
                  onChanged: (r) => setState(() => _role = r),
                        )
                            .animate()
                            .fadeIn(delay: 160.ms, duration: 400.ms),
                        const SizedBox(height: 18),
                        _softField(
                          focused: _nameFocus.hasFocus,
                          child: TextFormField(
                            controller: _name,
                            focusNode: _nameFocus,
                            style: _inputTextStyle,
                            textInputAction: TextInputAction.next,
                            decoration: _field(
                              hint: _t('ناوی تەواو', 'Full name', 'الاسم الكامل'),
                              icon: Icons.person_outline_rounded,
                              focused: _nameFocus.hasFocus,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? _t('ناو بنووسە', 'Enter your name', 'أدخل اسمك')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _softField(
                          focused: _phoneFocus.hasFocus,
                          child: TextFormField(
                            controller: _phone,
                            focusNode: _phoneFocus,
                            style: _inputTextStyle,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() {}),
                            onFieldSubmitted: (_) => _sendSignupOtp(),
                            decoration: _field(
                              hint: _t('ژمارەی مۆبایل', 'Mobile number', 'رقم الهاتف'),
                              icon: Icons.phone_outlined,
                              focused: _phoneFocus.hasFocus,
                              valid: PhoneUtils.isValid(_phone.text),
                              suffix: TextButton(
                                onPressed: (isLoading ||
                                        _otpSending ||
                                        _otpCooldownSecs > 0)
                                    ? null
                                    : _sendSignupOtp,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.brand,
                                  disabledForegroundColor:
                                      const Color(0xFF9AA8AA),
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: _otpSending
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.brand,
                                        ),
                                      )
                                    : Text(
                                        _otpCooldownSecs > 0
                                            ? '$_otpCooldownSecs'
                                            : _t('ناردنی کۆد', 'Send code', 'إرسال الرمز'),
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                        ),
                                      ),
                              ),
                            ),
                            validator: (v) =>
                                PhoneUtils.validate(v, language: _lang),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SignupOtpField(
                          controller: _otp,
                          focusNode: _otpFocus,
                          focused: _otpFocus.hasFocus,
                          label: _t(
                            'کۆدی پشتڕاستکردنەوە',
                            'Verification code',
                            'رمز التحقق',
                          ),
                          hint: _t(
                            'کۆدی ٦ ژمارەیی لە واتساپ یان SMS',
                            '6-digit code from WhatsApp or SMS',
                            'رمز مكون من 6 أرقام عبر واتساب أو SMS',
                          ),
                          validator: (v) {
                            if (v == null ||
                                !RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                              return _t(
                                'کۆدی ٦ ژمارەیی بنووسە',
                                'Enter the 6-digit code',
                                'أدخل الرمز المكون من 6 أرقام',
                              );
                            }
                            return null;
                          },
                        ),
                        if (_role == UserRole.shopOwner) ...[
                          const SizedBox(height: 14),
                          _softField(
                            focused: _shopFocus.hasFocus,
                            child: TextFormField(
                              controller: _shopName,
                              focusNode: _shopFocus,
                              style: _inputTextStyle,
                              textInputAction: TextInputAction.next,
                              decoration: _field(
                                hint: _t('ناوی دووکان', 'Shop name', 'اسم المتجر'),
                                icon: Icons.storefront_outlined,
                                focused: _shopFocus.hasFocus,
                              ),
                              validator: (v) {
                                if (_role != UserRole.shopOwner) return null;
                                if (v == null || v.trim().isEmpty) {
                                  return _t(
                                    'ناوی دووکان بنووسە',
                                    'Enter shop name',
                                    'أدخل اسم المتجر',
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _softField(
                          focused: _passFocus.hasFocus,
                          child: TextFormField(
                            controller: _password,
                            focusNode: _passFocus,
                            style: _inputTextStyle,
                            obscureText: _obscurePass,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            decoration: _field(
                              hint: _t('تێپەڕەوشە', 'Password', 'كلمة المرور'),
                              icon: Icons.lock_outline_rounded,
                              focused: _passFocus.hasFocus,
                              suffix: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePass = !_obscurePass,
                                ),
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF9AA8AA),
                                  size: 21,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return _t(
                                  'لانیکەم ٦ پیت بنووسە',
                                  'At least 6 characters',
                                  '6 أحرف على الأقل',
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        _softField(
                          focused: _confirmFocus.hasFocus,
                          child: TextFormField(
                            controller: _confirm,
                            focusNode: _confirmFocus,
                            style: _inputTextStyle,
                            obscureText: _obscureConfirm,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: _field(
                              hint: _t(
                                'دووبارە تێپەڕەوشە بنووسە',
                                'Confirm password',
                                'تأكيد كلمة المرور',
                              ),
                              icon: Icons.lock_outline_rounded,
                              focused: _confirmFocus.hasFocus,
                              suffix: IconButton(
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF9AA8AA),
                                  size: 21,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v != _password.text) {
                                return _t(
                                  'وشە نهێنییەکان یەک ناگرنەوە',
                                  'Passwords do not match',
                                  'كلمتا المرور غير متطابقتين',
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        _TermsRow(
                          accepted: _acceptedTerms,
                          language: _lang,
                          error: _termsError,
                          onChanged: (v) => setState(() {
                            _acceptedTerms = v;
                            _termsError = null;
                          }),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.lerp(AppColors.brand, Colors.white, 0.08) ??
                                      AppColors.brand,
                                  AppColors.brand,
                                  Color.lerp(AppColors.brand, const Color(0xFF0A3D42), 0.25) ??
                                      AppColors.brand,
                                ],
                              ),
                      boxShadow: [
                        BoxShadow(
                                  color: AppColors.brand.withValues(alpha: 0.32),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
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
                                      _t('هەژمار دروست بکە', 'Create account',
                                          'إنشاء حساب'),
                                      style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w800,
                                        fontSize: 16.5,
                              ),
                            ),
                    ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 220.ms, duration: 450.ms)
                            .slideY(begin: 0.08, curve: Curves.easeOutCubic),
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

class _SignupBackdrop extends StatelessWidget {
  const _SignupBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
      children: [
          const ColoredBox(color: Color(0xFFFAFCFC)),
          Positioned(
            top: -40,
            left: -30,
            child: Container(
              width: 180,
              height: 180,
                decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brand.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.highlight.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Soft orange arc (mockup accent)
          Positioned(
            top: 12,
            right: 36,
            child: CustomPaint(
              size: const Size(90, 70),
              painter: _ArcPainter(
                color: AppColors.highlight.withValues(alpha: 0.35),
              ),
          ),
        ),
      ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.05,
        size.width * 0.95,
        size.height * 0.45,
      );
    canvas.drawPath(path, paint);
    final path2 = Path()
      ..moveTo(size.width * 0.2, size.height * 0.95)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.25,
        size.width,
        size.height * 0.55,
      );
    canvas.drawPath(path2, paint..color = color.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SignupHeroHeader extends StatelessWidget {
  final AppLanguage language;

  const _SignupHeroHeader({required this.language});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 186,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
      children: [
          // Dot grid
          Positioned(
            left: 18,
            top: 6,
            child: SizedBox(
              width: 54,
              height: 36,
              child: CustomPaint(
                painter: _DotGridPainter(
                  color: AppColors.brand.withValues(alpha: 0.16),
                ),
              ),
            ),
          ),
          Positioned(
            left: -6,
            top: 28,
            child: _FashionBubble(
              size: 118,
              asset: 'assets/images/login_scene.png',
              overlay: AppColors.brand.withValues(alpha: 0.38),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            right: -10,
            top: 4,
            child: Transform.rotate(
              angle: 0.06,
              child: _FashionBubble(
                size: 128,
                asset: 'assets/images/login_hero.png',
                overlay: Colors.black.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(78),
                  topRight: Radius.circular(32),
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(78),
                ),
              ),
            ),
          ),
          // Soft white veil behind logo so text stays readable
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.92),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    AppColors.brand,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset('assets/images/qopcha_logo.png'),
                ),
              ),
              const SizedBox(height: 10),
                    Text(
                AppConstants.appName,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  color: AppColors.brand,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Q O P C H A',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  letterSpacing: 3.6,
                  color: AppColors.highlight,
                      ),
                    ),
              const SizedBox(height: 5),
                    Text(
                tr(
                  language,
                  AppConstants.appTagline,
                  'Modern clothing for everyone',
                  'أزياء عصرية للجميع',
                ),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  color: AppColors.brand.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  const _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const cols = 4;
    const rows = 3;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final dx = (size.width / (cols - 1)) * c;
        final dy = (size.height / (rows - 1)) * r;
        canvas.drawCircle(Offset(dx, dy), 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FashionBubble extends StatelessWidget {
  final double size;
  final String asset;
  final Color? overlay;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  const _FashionBubble({
    required this.size,
    required this.asset,
    required this.overlay,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size / 2);
    return Container(
      width: size,
      height: size,
          decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
            children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: AppColors.brand.withValues(alpha: 0.12),
            ),
          ),
          if (overlay != null) ColoredBox(color: overlay!),
          // Soft edge fade
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.08),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  final UserRole role;
  final AppLanguage language;
  final ValueChanged<UserRole> onChanged;

  const _RoleToggle({
    required this.role,
    required this.language,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
        color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
                        ),
                        child: Row(
                          children: [
          _chip(
            selected: role == UserRole.customer,
            label: tr(language, 'کڕیار', 'Customer', 'عميل'),
            onTap: () => onChanged(UserRole.customer),
          ),
          _chip(
            selected: role == UserRole.shopOwner,
            label: tr(language, 'دووکان', 'Shop', 'متجر'),
            onTap: () => onChanged(UserRole.shopOwner),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
          color: selected ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
          ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: selected ? Colors.white : AppColors.brand,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  final bool accepted;
  final AppLanguage language;
  final String? error;
  final ValueChanged<bool> onChanged;

  const _TermsRow({
    required this.accepted,
    required this.language,
    required this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
                        fontFamily: AppTheme.fontFamily,
      fontSize: 12.8,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF6A7A7C),
      height: 1.45,
    );
    final accent = base.copyWith(
      color: AppColors.highlight,
                        fontWeight: FontWeight.w800,
    );
    void openTerms() => context.push(LegalDocumentScreen.routeFor(
          LegalDocumentKind.terms,
        ));
    void openPrivacy() => context.push(LegalDocumentScreen.routeFor(
          LegalDocumentKind.privacy,
        ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => onChanged(!accepted),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onChanged(!accepted),
            child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
                  margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
                    color: accepted ? AppColors.brand : Colors.white,
                    borderRadius: BorderRadius.circular(7),
              border: Border.all(
                      color: error != null
                          ? AppColors.error
                          : accepted
                              ? AppColors.brand
                              : const Color(0xFFB8C6C7),
                      width: 1.4,
                    ),
                  ),
                  child: accepted
                      ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                      : null,
                ),
          ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: base,
                      children: language == AppLanguage.english
                          ? [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'terms',
                                style: accent,
                                recognizer: TapGestureRecognizer()
                                  ..onTap = openTerms,
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'privacy policy',
                                style: accent,
                                recognizer: TapGestureRecognizer()
                                  ..onTap = openPrivacy,
                              ),
                            ]
                          : language == AppLanguage.arabic
                              ? [
                                  const TextSpan(text: 'أوافق على '),
                                  TextSpan(
                                    text: 'الشروط',
                                    style: accent,
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = openTerms,
                                  ),
                                  const TextSpan(text: ' و '),
                                  TextSpan(
                                    text: 'سياسة الخصوصية',
                                    style: accent,
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = openPrivacy,
                                  ),
                                ]
                              : [
                                  const TextSpan(text: 'من ڕازیم بە هەموو '),
                                  TextSpan(
                                    text: 'مەرج',
                                    style: accent,
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = openTerms,
                                  ),
                                  const TextSpan(text: ' و '),
                                  TextSpan(
                                    text: 'سیاسەتەکان',
                                    style: accent,
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = openPrivacy,
                                  ),
                                ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _SignupOtpField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  const _SignupOtpField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.label,
    required this.hint,
    this.validator,
  });

  @override
  State<_SignupOtpField> createState() => _SignupOtpFieldState();
}

class _SignupOtpFieldState extends State<_SignupOtpField>
    with TickerProviderStateMixin {
  late final AnimationController _cursorBlink;
  late final AnimationController _successPop;
  bool _wasComplete = false;

  bool get _complete =>
      RegExp(r'^\d{6}$').hasMatch(widget.controller.text.trim());

  @override
  void initState() {
    super.initState();
    _cursorBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _successPop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    widget.controller.addListener(_onCodeChanged);
    _wasComplete = _complete;
    if (_wasComplete) _successPop.value = 1;
  }

  void _onCodeChanged() {
    final nowComplete = _complete;
    if (nowComplete && !_wasComplete) {
      HapticFeedback.mediumImpact();
      _successPop.forward(from: 0);
    } else if (!nowComplete && _wasComplete) {
      _successPop.reverse();
    }
    _wasComplete = nowComplete;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCodeChanged);
    _cursorBlink.dispose();
    _successPop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final complete = _complete;
    final successT = CurvedAnimation(
      parent: _successPop,
      curve: Curves.easeOutBack,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: complete
                      ? AppColors.success.withValues(alpha: 0.14)
                      : AppColors.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 340),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (child, anim) {
                    return ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    );
                  },
                  child: Icon(
                    complete
                        ? Icons.check_circle_rounded
                        : Icons.mark_chat_read_outlined,
                    key: ValueKey(complete),
                    size: 18,
                    color: complete ? AppColors.success : AppColors.brand,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: const Color(0xFF152426),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.hint,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 11.5,
                        color: const Color(0xFF7E8E90),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              ScaleTransition(
                scale: successT,
                child: FadeTransition(
                  opacity: successT,
                  child: Icon(
                    Icons.verified_rounded,
                    color: AppColors.success,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: complete
                    ? AppColors.success.withValues(alpha: 0.16)
                    : widget.focused
                        ? AppColors.brand.withValues(alpha: 0.16)
                        : Colors.black.withValues(alpha: 0.045),
                blurRadius: widget.focused || complete ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: widget.focusNode.requestFocus,
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: complete
                        ? AppColors.success
                        : widget.focused
                            ? AppColors.brand
                            : const Color(0xFFE2EBEC),
                    width: widget.focused || complete ? 1.6 : 1,
                  ),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            children: List.generate(6, (i) {
                              final digit = i < code.length ? code[i] : '';
                              final active = widget.focused &&
                                  !complete &&
                                  (code.length == i ||
                                      (code.length == 6 && i == 5));
                              final filled = digit.isNotEmpty;
                              return Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  margin: EdgeInsetsDirectional.only(
                                    start: i == 0 ? 0 : 4,
                                    end: i == 5 ? 0 : 4,
                                  ),
                                  height: 54,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: complete
                                        ? LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              AppColors.success
                                                  .withValues(alpha: 0.16),
                                              AppColors.success
                                                  .withValues(alpha: 0.05),
                                            ],
                                          )
                                        : active
                                            ? LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  AppColors.brand
                                                      .withValues(alpha: 0.12),
                                                  AppColors.brand
                                                      .withValues(alpha: 0.04),
                                                ],
                                              )
                                            : null,
                                    color: complete || active
                                        ? null
                                        : filled
                                            ? AppColors.brand
                                                .withValues(alpha: 0.07)
                                            : const Color(0xFFF7FBFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: complete
                                          ? AppColors.success
                                          : active
                                              ? AppColors.brand
                                              : filled
                                                  ? AppColors.brand
                                                      .withValues(alpha: 0.55)
                                                  : const Color(0xFFD8E4E6),
                                      width: active || complete ? 2 : 1.1,
                                    ),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: AppColors.brand
                                                  .withValues(alpha: 0.18),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : complete
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.success
                                                      .withValues(alpha: 0.14),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                  ),
                                  child: filled
                                      ? AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 280,
                                          ),
                                          switchInCurve: Curves.easeOutBack,
                                          transitionBuilder: (child, anim) {
                                            return ScaleTransition(
                                              scale: anim,
                                              child: FadeTransition(
                                                opacity: anim,
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: complete
                                              ? Icon(
                                                  Icons.check_rounded,
                                                  key: ValueKey('ok-$i'),
                                                  color: AppColors.success,
                                                  size: 26,
                                                )
                                              : Text(
                                                  digit,
                                                  key: ValueKey('d-$i-$digit'),
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        AppTheme.fontFamily,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 23,
                                                    color: Color(0xFF152426),
                                                    height: 1,
                                                  ),
                                                ),
                                        )
                                      : active
                                          ? FadeTransition(
                                              opacity: _cursorBlink,
                                              child: Container(
                                                width: 2,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: AppColors.brand,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(0xFFC9D5D7),
                                              ),
                                            ),
                                ),
                              );
                            }),
                          ),
                          Opacity(
                            opacity: 0.01,
                            child: SizedBox(
                              height: 54,
                              child: TextFormField(
                                controller: widget.controller,
                                focusNode: widget.focusNode,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                maxLength: 6,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: widget.validator,
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    HapticFeedback.selectionClick();
                                  }
                                  if (value.length == 6) {
                                    HapticFeedback.lightImpact();
                                    FocusScope.of(context).nextFocus();
                                  }
                                },
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  errorStyle: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 0.01,
                                  height: 0.01,
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
