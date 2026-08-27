import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Shown for rejected accounts, and for pending shop owners.
/// Pending customers browse the app instead (with order lock).
class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final rejected = user?.isRejected == true;
    final reason = user?.rejectionReason?.trim();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: (rejected ? AppColors.error : AppColors.brand)
                      .withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  rejected
                      ? Icons.warning_amber_rounded
                      : Icons.hourglass_top_rounded,
                  size: 40,
                  color: rejected ? AppColors.error : AppColors.brand,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                rejected ? 'هەژمار ڕەتکرایەوە' : 'چاوەڕوانی پەسەندکردن',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                rejected
                    ? 'ببورە، هەژمارەکەت پەسەند نەکرا. خوارەوە هۆکاری ڕەتکردنەوە دەبینیت.'
                    : user?.isShopOwner == true
                        ? 'هەژماری دووکانەکەت نێردرا بۆ پەسەندکردن. دوای پەسەندکردنی ئەدمین دەتوانیت بەردەوام بیت.'
                        : 'هەژمارەکەت چاوەڕوانی پەسەندکردنی ئەدمینە. دەتوانیت بەرهەمەکان ببینیت، بەڵام ناتوانیت داواکاری بکەیت.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (rejected) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'هۆکاری ڕەتکردنەوە',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (reason == null || reason.isEmpty)
                            ? 'هەژمارەکەت لەلایەن ئەدمینەوە ڕەتکرایەوە'
                            : reason,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (user != null) ...[
                const SizedBox(height: 20),
                Text(
                  user.email,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const Spacer(),
              if (!rejected && user?.isCustomer == true) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('بینینی بەرهەمەکان'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'چوونەدەرەوە',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
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
