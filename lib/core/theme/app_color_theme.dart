import 'package:flutter/material.dart';

/// User-selectable brand color packs (independent of light/dark mode).
enum AppColorTheme {
  red,
  orange,
  yellow,
  ocean,
  teal,
  violet;

  static AppColorTheme resolve(String? name) {
    if (name == null) return AppColorTheme.teal;
    for (final t in AppColorTheme.values) {
      if (t.name == name) return t;
    }
    // Migrate removed legacy theme names.
    return switch (name) {
      'qopcha' || 'aurora' || 'forest' => AppColorTheme.teal,
      'citrus' || 'sand' => AppColorTheme.yellow,
      'ember' => AppColorTheme.orange,
      'midnight' || 'arctic' => AppColorTheme.ocean,
      'graphite' => AppColorTheme.violet,
      _ => AppColorTheme.teal,
    };
  }

  String get labelKu => switch (this) {
        AppColorTheme.red => 'سور',
        AppColorTheme.orange => 'پرتەقاڵی',
        AppColorTheme.yellow => 'زەرد',
        AppColorTheme.ocean => 'زەریا',
        AppColorTheme.teal => 'قۆپچە',
        AppColorTheme.violet => 'مۆر',
      };

  String get subtitleKu => switch (this) {
        AppColorTheme.red => 'سور و گەرم',
        AppColorTheme.orange => 'پرتەقاڵی و خۆر',
        AppColorTheme.yellow => 'زەرد و خۆر',
        AppColorTheme.ocean => 'شینی قووڵ و ئاو',
        AppColorTheme.teal => 'تیڵ و پڕتەقاڵی — بنەڕەتی',
        AppColorTheme.violet => 'مۆر و پەمەیی',
      };

  Color get brand => switch (this) {
        AppColorTheme.red => const Color(0xFFC62828),
        AppColorTheme.orange => const Color(0xFFE65100),
        AppColorTheme.yellow => const Color(0xFFC9A000),
        AppColorTheme.ocean => const Color(0xFF0E5A8A),
        AppColorTheme.teal => const Color(0xFF116C71),
        AppColorTheme.violet => const Color(0xFF5E35B1),
      };

  Color get highlight => switch (this) {
        AppColorTheme.red => const Color(0xFFFF5252),
        AppColorTheme.orange => const Color(0xFFFF9800),
        AppColorTheme.yellow => const Color(0xFFFFD54F),
        AppColorTheme.ocean => const Color(0xFF4FC3F7),
        AppColorTheme.teal => const Color(0xFFF15C22),
        AppColorTheme.violet => const Color(0xFFCE93D8),
      };

  Color get brandLight => switch (this) {
        AppColorTheme.red => const Color(0xFFE53935),
        AppColorTheme.orange => const Color(0xFFFF7043),
        AppColorTheme.yellow => const Color(0xFFF9A825),
        AppColorTheme.ocean => const Color(0xFF2F7FB5),
        AppColorTheme.teal => const Color(0xFF2A9AA3),
        AppColorTheme.violet => const Color(0xFF7E57C2),
      };

  Color get gradientStart => switch (this) {
        AppColorTheme.red => const Color(0xFF5C1010),
        AppColorTheme.orange => const Color(0xFF4A2500),
        AppColorTheme.yellow => const Color(0xFF4A3800),
        AppColorTheme.ocean => const Color(0xFF083A5C),
        AppColorTheme.teal => const Color(0xFF0D3D42),
        AppColorTheme.violet => const Color(0xFF2D1B4E),
      };

  Color get gradientEnd => switch (this) {
        AppColorTheme.red => const Color(0xFF8B1A1A),
        AppColorTheme.orange => const Color(0xFF7A3A00),
        AppColorTheme.yellow => const Color(0xFF7A5C00),
        AppColorTheme.ocean => const Color(0xFF0A4A72),
        AppColorTheme.teal => const Color(0xFF0A555C),
        AppColorTheme.violet => const Color(0xFF4527A0),
      };
}
