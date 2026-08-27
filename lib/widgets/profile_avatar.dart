import 'package:flutter/material.dart';

import '../core/constants/profile_avatars.dart';
import '../core/theme/app_theme.dart';

/// Renders a built-in profile icon (or name initial as fallback).
class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? avatarValue;
  final double size;
  final bool showBorder;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.avatarValue,
    this.size = 48,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final option = ProfileAvatars.optionFor(avatarValue);

    if (option != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: option.color.withValues(alpha: 0.14),
          border: showBorder
              ? Border.all(color: option.color.withValues(alpha: 0.35), width: 2)
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          option.icon,
          size: size * 0.52,
          color: option.color,
        ),
      );
    }

    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.brand.withValues(alpha: 0.12),
        border: showBorder
            ? Border.all(
                color: AppColors.brand.withValues(alpha: 0.3),
                width: 2,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: AppColors.brand,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
