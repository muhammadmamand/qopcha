import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';

/// Shows a short prompt asking the guest to sign in.
/// Returns `true` if they chose to go to login.
Future<bool> showLoginRequiredDialog(
  BuildContext context, {
  String? message,
  String? nextPath,
}) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.sheet,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        'پێویستە بچیتە ژوورەوە',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        message ??
            'بۆ داواکردن پێویستە هەژمارت هەبێت. تکایە بچۆ ژوورەوە یان هەژمار دروست بکە.',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'دواتر',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
          ),
          child: Text(
            'چوونەژوورەوە',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  if (go == true && context.mounted) {
    final next = (nextPath ?? '').trim();
    final path = next.isEmpty
        ? '/auth'
        : '/auth?next=${Uri.encodeComponent(next)}';
    context.push(path);
    return true;
  }
  return false;
}
