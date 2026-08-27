import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Blocks the app until the user verifies their email (Firebase Auth).
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _checking = false;
  bool _resending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        t.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _resend() async {
    if (_resending || _cooldownSeconds > 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _resending = true;
      _message = null;
    });
    final error =
        await ref.read(authProvider.notifier).resendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _resending = false;
      if (error == null) {
        _messageIsError = false;
        _message = 'ئیمەیڵی پشتڕاستکردنەوە نێردرایەوە — سندوقی نامەکان بپشکنە';
        _startCooldown();
      } else {
        _messageIsError = true;
        _message = error;
      }
    });
  }

  Future<void> _checkVerified() async {
    if (_checking) return;
    HapticFeedback.selectionClick();
    setState(() {
      _checking = true;
      _message = null;
    });
    final ok = await ref.read(authProvider.notifier).checkEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);
    if (ok) {
      // Router redirect will take the user home.
      return;
    }
    setState(() {
      _messageIsError = true;
      _message =
          'هێشتا پشتڕاست نەکراوە. لینکەکەی ناو ئیمەیڵ بکەرەوە، پاشان دووبارە هەوڵبدەرەوە';
    });
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email.trim().isNotEmpty == true
        ? user!.email.trim()
        : (ref.read(authServiceProvider).currentAuthEmail ?? '');

    return Scaffold(
      backgroundColor: AppColors.isDark
          ? AppColors.surface
          : const Color(0xFFF4F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _logout,
                  style: TextButton.styleFrom(foregroundColor: AppColors.brand),
                  child: Text(
                    'چوونەدەرەوە',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_rounded,
                  size: 46,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'ئیمەیڵەکەت پشتڕاست بکەرەوە',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'لینکێکمان نارد بۆ ئیمەیڵەکەت. تکایە بیکەرەوە بۆ چالاککردنی هەژمارەکەت.\n\nئەگەر نەهات: Spam / Junk بپشکنە، یان دووبارە بنێرەوە.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        color: AppColors.brand,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          email,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: (_messageIsError ? AppColors.error : AppColors.brand)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _messageIsError
                          ? AppColors.error
                          : AppColors.brand,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _checking ? null : _checkVerified,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _checking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'پشتڕاستم کرد — بەردەوامبە',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed:
                      (_resending || _cooldownSeconds > 0) ? null : _resend,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    side: BorderSide(
                      color: AppColors.brand.withValues(
                        alpha: (_resending || _cooldownSeconds > 0) ? 0.35 : 1,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _resending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Text(
                          _cooldownSeconds > 0
                              ? 'دووبارە ناردنەوە ($_cooldownSeconds)'
                              : 'دووبارە ناردنەوەی ئیمەیڵ',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
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
