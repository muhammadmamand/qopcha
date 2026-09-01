import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/language_switcher.dart';

/// Full-page forgot password: phone → OTP → new password.
class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  final String? initialPhone;

  const ForgotPasswordOtpScreen({super.key, this.initialPhone});

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState
    extends ConsumerState<ForgotPasswordOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpFocus = FocusNode();

  /// 0 phone · 1 OTP · 2 new password
  int _step = 0;
  bool _busy = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;
  String _phone = '';
  int _cooldownSecs = 0;
  Timer? _cooldownTimer;

  AppLanguage get _lang => ref.watch(appSettingsProvider).language;
  String _t(String ku, String en, [String? ar]) =>
      tr(_lang, ku, en, ar ?? ku);

  @override
  void initState() {
    super.initState();
    final seed = (widget.initialPhone ?? '').trim();
    _phoneController = TextEditingController(text: seed);
    _codeController.addListener(() => setState(() {}));
    if (seed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final normalized = PhoneUtils.normalize(seed);
        if (PhoneUtils.isValid(normalized)) {
          _sendCode(auto: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 45]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSecs = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldownSecs <= 1) {
        t.cancel();
        setState(() => _cooldownSecs = 0);
      } else {
        setState(() => _cooldownSecs -= 1);
      }
    });
  }

  Future<void> _sendCode({bool auto = false}) async {
    setState(() => _error = null);
    if (!auto && _step == 0 && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final phone = PhoneUtils.normalize(_phoneController.text);
    final phoneError = PhoneUtils.validate(phone, language: _lang);
    if (phoneError != null) {
      setState(() => _error = phoneError);
      return;
    }
    if (_cooldownSecs > 0 && _step == 1) return;

    setState(() => _busy = true);
    final result =
        await ref.read(authProvider.notifier).requestPasswordResetCode(phone);
    if (!mounted) return;

    if (result.error != null) {
      setState(() {
        _busy = false;
        _error = result.error;
      });
      return;
    }

    setState(() {
      _busy = false;
      _phone = phone;
      _step = 1;
      _codeController.clear();
    });
    _startCooldown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocus.requestFocus();
    });
  }

  Future<void> _goToNewPassword() async {
    setState(() => _error = null);
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(
        () => _error = _t('کۆدی ٦ ژمارەیی بنووسە', 'Enter the 6-digit code'),
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _step = 2);
  }

  Future<void> _confirmReset() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    final error = await ref.read(authProvider.notifier).resetPasswordWithCode(
          phone: _phone.isEmpty
              ? PhoneUtils.normalize(_phoneController.text)
              : _phone,
          code: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }

    setState(() => _busy = false);
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/auth');
    }
  }

  Future<void> _onPrimary() async {
    if (_step == 0) {
      await _sendCode();
    } else if (_step == 1) {
      await _goToNewPassword();
    } else {
      await _confirmReset();
    }
  }

  void _onBack() {
    if (_busy) return;
    if (_step > 0) {
      setState(() {
        _error = null;
        _step -= 1;
      });
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = AppColors.isDark
        ? const Color(0xFF0E1516)
        : const Color(0xFFEEF5F8);

    if (_step == 1) {
      return Scaffold(
        backgroundColor: pageBg,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    onPressed: _onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: _buildVerifyOtpCard(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final title = _step == 0
        ? _t('وشەی نهێنیم لەبیرچووە', 'Forgot password', 'نسيت كلمة المرور')
        : _t('وشەی نهێنی نوێ', 'New password', 'كلمة مرور جديدة');
    final subtitle = _step == 0
        ? _t(
            'ژمارەی مۆبایلەکەت بنووسە — کۆد بە واتساپ یان SMS دەنێردرێت.',
            'Enter your phone — a code will be sent by WhatsApp or SMS.',
            'أدخل رقم هاتفك — سيتم إرسال الرمز عبر واتساب أو SMS.',
          )
        : _t(
            'وشەی نهێنی نوێ دابنێ و دووبارەی بکەرەوە.',
            'Set a new password and confirm it.',
            'ضع كلمة مرور جديدة ثم أكدها.',
          );
    final cta = _step == 0
        ? _t('ناردنی کۆد', 'Send code', 'إرسال الرمز')
        : _t('گۆڕینی وشەی نهێنی', 'Reset password', 'إعادة تعيين كلمة المرور');

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: _busy ? null : _onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 8),
            child: LanguageSwitcherButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            children: [
              _StepDots(step: _step),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _step == 0
                            ? Icons.lock_reset_rounded
                            : Icons.lock_outline_rounded,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.5,
                          height: 1.45,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              if (_step == 0) ...[
                _label(_t('ژمارەی مۆبایل', 'Phone number')),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.done,
                  enabled: !_busy,
                  onFieldSubmitted: (_) => _sendCode(),
                  style: _fieldStyle,
                  cursorColor: AppColors.brand,
                  validator: (v) => PhoneUtils.validate(v, language: _lang),
                  decoration: _decoration(
                    hint: '07xxxxxxxxx',
                    icon: Icons.phone_outlined,
                  ),
                ),
              ] else ...[
                _label(_t('وشەی نهێنی نوێ', 'New password')),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePass,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  enabled: !_busy,
                  style: _fieldStyle,
                  cursorColor: AppColors.brand,
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return _t(
                        'لانیکەم ٦ کاراکتەر بنووسە',
                        'At least 6 characters',
                      );
                    }
                    return null;
                  },
                  decoration: _decoration(
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label(_t('دووبارەکردنەوە', 'Confirm password')),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.done,
                  enabled: !_busy,
                  onFieldSubmitted: (_) => _confirmReset(),
                  style: _fieldStyle,
                  cursorColor: AppColors.brand,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return _t(
                        'وشەی نهێنی دووبارە بکەرەوە',
                        'Confirm your password',
                      );
                    }
                    if (v != _passwordController.text) {
                      return _t(
                        'وشە نهێنییەکان یەک ناگرنەوە',
                        'Passwords do not match',
                      );
                    }
                    return null;
                  },
                  decoration: _decoration(
                    hint: '••••••••',
                    icon: Icons.lock_person_outlined,
                    suffix: IconButton(
                      onPressed: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                _errorBox(_error!),
              ],
              const SizedBox(height: 28),
              _primaryButton(label: cta, onPressed: _busy ? null : _onPrimary),
            ],
          ),
        ),
      ),
    );
  }

  /// Second-screenshot style: centered white card + 6 OTP boxes.
  Widget _buildVerifyOtpCard() {
    final code = _codeController.text;
    final displayPhone = _phone.isEmpty ? _phoneController.text.trim() : _phone;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _OtpBadge(),
          const SizedBox(height: 18),
          Text(
            _t('پشتڕاستکردنەوەی کۆد', 'Verify OTP'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _t(
              'کۆدی ٦ ژمارەیی بنووسە کە بۆ $displayPhone نێردرا',
              'Enter the 6-digit code sent to $displayPhone',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: List.generate(6, (i) {
                    final digit = i < code.length ? code[i] : '';
                    final focused = _otpFocus.hasFocus &&
                        (code.length == i ||
                            (code.length == 6 && i == 5));
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: EdgeInsetsDirectional.only(
                          start: i == 0 ? 0 : 5,
                          end: i == 5 ? 0 : 5,
                        ),
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.isDark
                              ? AppColors.surfaceVariant.withValues(alpha: 0.35)
                              : const Color(0xFFF7FBFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: focused || digit.isNotEmpty
                                ? AppColors.brand
                                : AppColors.brand.withValues(alpha: 0.28),
                            width: focused ? 1.6 : 1.15,
                          ),
                        ),
                        child: Text(
                          digit,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Opacity(
                  opacity: 0.01,
                  child: TextField(
                    controller: _codeController,
                    focusNode: _otpFocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    autofocus: true,
                    enabled: !_busy,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      if (v.length == 6) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    onSubmitted: (_) => _goToNewPassword(),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _t('کۆدت نەگەیشت؟ ', "Didn't receive code? "),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: (_busy || _cooldownSecs > 0)
                    ? null
                    : () => _sendCode(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.brand,
                  disabledForegroundColor:
                      AppColors.textTertiary.withValues(alpha: 0.8),
                ),
                child: Text(
                  _cooldownSecs > 0
                      ? _t(
                          'دووبارە ناردن ($_cooldownSecs)',
                          'Resend ($_cooldownSecs)',
                        )
                      : _t('دووبارە ناردنی کۆد', 'Resend OTP'),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            _errorBox(_error!),
          ],
          const SizedBox(height: 22),
          _primaryButton(
            label: _t('پشتڕاستکردنەوەی کۆد', 'Verify OTP'),
            onPressed: _busy ? null : _goToNewPassword,
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.error,
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }

  TextStyle get _fieldStyle => TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.brand, size: 20),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 60, minHeight: 52),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.85)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.brand, width: 1.5),
      ),
      errorStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.error,
      ),
    );
  }
}

class _OtpBadge extends StatelessWidget {
  const _OtpBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand.withValues(alpha: 0.10),
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand.withValues(alpha: 0.18),
            ),
          ),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand,
            ),
            child: const Text(
              'OTP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int step;
  const _StepDots({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i <= step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active && i == step ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.brand
                : AppColors.border.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
