import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/admin_security.dart';
import '../../core/platform/app_host.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Separate admin console login — light, branded staff entry.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final success = await ref.read(authProvider.notifier).loginAsAdmin(
          _email.text.trim(),
          _password.text,
        );

    if (!mounted) return;

    if (success) {
      context.go('/admin');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authProvider).error ?? 'چوونەژوورەوە سەرکەوتوو نەبوو',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: 0.16),
                    AppColors.brand.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.highlight.withValues(alpha: 0.12),
                    AppColors.highlight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 460 : 520),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(22, 16, 22, 24 + keyboard),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!AppHost.isAdminWebConsole)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: IconButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/auth');
                              }
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textSecondary,
                            ),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.9),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.08),
                              blurRadius: 32,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brand
                                          .withValues(alpha: 0.28),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Image.asset(
                                    'assets/images/qopcha_logo.png',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'پانێڵی بەڕێوەبردن',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'تەنها بۆ ئەدمینی ڕێگەپێدراو — جیاوازە لە چوونەژوورەوەی کڕیار و دووکان.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _Label('ئیمەیڵی ئەدمین'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _email,
                                      focusNode: _emailFocus,
                                      keyboardType: TextInputType.emailAddress,
                                      textDirection: TextDirection.ltr,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) =>
                                          _passwordFocus.requestFocus(),
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: _lightFieldDecoration(
                                        hint: 'admin@…',
                                        icon: Icons.mail_outline_rounded,
                                      ),
                                      validator: (v) {
                                        final email = v?.trim() ?? '';
                                        if (email.isEmpty) {
                                          return 'ئیمەیڵ بنووسە';
                                        }
                                        if (!AdminSecurity.isAllowedAdminEmail(
                                          email,
                                        )) {
                                          return 'ئەم ئیمەیڵە ڕێگەپێدراو نییە بۆ ئەدمین';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _Label('وشەی نهێنی'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _password,
                                      focusNode: _passwordFocus,
                                      obscureText: _obscure,
                                      textDirection: TextDirection.ltr,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _login(),
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: _lightFieldDecoration(
                                        hint: '••••••••',
                                        icon: Icons.lock_outline_rounded,
                                        suffix: IconButton(
                                          onPressed: () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ),
                                      validator: (v) =>
                                          v == null || v.length < 6
                                              ? 'وشەی نهێنی بنووسە'
                                              : null,
                                    ),
                                    const SizedBox(height: 22),
                                    SizedBox(
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: loading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.brand,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: AppColors
                                              .brand
                                              .withValues(alpha: 0.45),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: loading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                'چوونەژوورەوە بۆ پانێڵ',
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTheme.fontFamily,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _lightFieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: AppColors.textTertiary,
      ),
      prefixIcon: Icon(icon, color: AppColors.brand),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.brand, width: 1.5),
      ),
      errorStyle: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: AppColors.error,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
    );
  }
}
