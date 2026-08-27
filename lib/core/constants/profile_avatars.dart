import 'package:flutter/material.dart';

/// Built-in profile icons (no photo upload).
/// Stored in [UserModel.avatarUrl] as `avatar:<id>`.
class ProfileAvatarOption {
  final String id;
  final IconData icon;
  final Color color;
  final String labelKu;

  const ProfileAvatarOption({
    required this.id,
    required this.icon,
    required this.color,
    required this.labelKu,
  });

  String get storageValue => 'avatar:$id';
}

class ProfileAvatars {
  static const prefix = 'avatar:';

  static const List<ProfileAvatarOption> all = [
    ProfileAvatarOption(
      id: 'user',
      icon: Icons.person_rounded,
      color: Color(0xFF146B72),
      labelKu: 'بەکارهێنەر',
    ),
    ProfileAvatarOption(
      id: 'smile',
      icon: Icons.sentiment_satisfied_alt_rounded,
      color: Color(0xFFF15C22),
      labelKu: 'خەندە',
    ),
    ProfileAvatarOption(
      id: 'star',
      icon: Icons.star_rounded,
      color: Color(0xFFD97706),
      labelKu: 'ئەستێرە',
    ),
    ProfileAvatarOption(
      id: 'favorite',
      icon: Icons.favorite_rounded,
      color: Color(0xFFE11D48),
      labelKu: 'دڵ',
    ),
    ProfileAvatarOption(
      id: 'bolt',
      icon: Icons.bolt_rounded,
      color: Color(0xFF7C3AED),
      labelKu: 'وزە',
    ),
    ProfileAvatarOption(
      id: 'pets',
      icon: Icons.pets_rounded,
      color: Color(0xFF059669),
      labelKu: 'ئاژەڵ',
    ),
    ProfileAvatarOption(
      id: 'music',
      icon: Icons.music_note_rounded,
      color: Color(0xFF2563EB),
      labelKu: 'میوزیک',
    ),
    ProfileAvatarOption(
      id: 'sports',
      icon: Icons.sports_soccer_rounded,
      color: Color(0xFF0F766E),
      labelKu: 'وەرزش',
    ),
    ProfileAvatarOption(
      id: 'shop',
      icon: Icons.storefront_rounded,
      color: Color(0xFFB45309),
      labelKu: 'دووکان',
    ),
    ProfileAvatarOption(
      id: 'coffee',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF78716C),
      labelKu: 'قاوە',
    ),
    ProfileAvatarOption(
      id: 'flight',
      icon: Icons.flight_rounded,
      color: Color(0xFF0284C7),
      labelKu: 'گەشت',
    ),
    ProfileAvatarOption(
      id: 'palette',
      icon: Icons.palette_rounded,
      color: Color(0xFFDB2777),
      labelKu: 'هونەر',
    ),
  ];

  static ProfileAvatarOption get defaultOption => all.first;

  static bool isIconValue(String? value) {
    final v = value?.trim() ?? '';
    return v.startsWith(prefix);
  }

  static ProfileAvatarOption? optionFor(String? value) {
    final v = value?.trim() ?? '';
    if (!v.startsWith(prefix)) return null;
    final id = v.substring(prefix.length);
    for (final o in all) {
      if (o.id == id) return o;
    }
    return null;
  }

  static ProfileAvatarOption resolve(String? value) {
    return optionFor(value) ?? defaultOption;
  }
}
