import 'package:flutter/material.dart';

/// User-selectable brand color packs (independent of light/dark mode).
enum AppColorTheme {
  red,
  orange,
  yellow,
  ocean,
  teal,
  violet,
  rose,
  blossom,
  peony;

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

  bool get isFloral => switch (this) {
        rose || blossom || peony => true,
        _ => false,
      };

  FloralMotif get floralMotif => switch (this) {
        AppColorTheme.rose => FloralMotif.rose,
        AppColorTheme.blossom => FloralMotif.blossom,
        AppColorTheme.peony => FloralMotif.peony,
        _ => FloralMotif.none,
      };

  String get labelKu => switch (this) {
        AppColorTheme.red => 'سور',
        AppColorTheme.orange => 'پرتەقاڵی',
        AppColorTheme.yellow => 'زەرد',
        AppColorTheme.ocean => 'زەریا',
        AppColorTheme.teal => 'قۆپچە',
        AppColorTheme.violet => 'مۆر',
        AppColorTheme.rose => 'گوڵەبی',
        AppColorTheme.blossom => 'گوڵی بەهار',
        AppColorTheme.peony => 'گوڵی پێۆنی',
      };

  String get subtitleKu => switch (this) {
        AppColorTheme.red => 'سور و گەرم',
        AppColorTheme.orange => 'پرتەقاڵی و خۆر',
        AppColorTheme.yellow => 'زەرد و خۆر',
        AppColorTheme.ocean => 'شینی قووڵ و ئاو',
        AppColorTheme.teal => 'تیڵ و پڕتەقاڵی — بنەڕەتی',
        AppColorTheme.violet => 'مۆر و پەمەیی',
        AppColorTheme.rose => 'گوڵەبی و گوڵە گوڵ',
        AppColorTheme.blossom => 'پەمەیی نەرم و گوڵی بەهار',
        AppColorTheme.peony => 'پەمەیی کاڵ و گوڵی پێۆنی',
      };

  Color get brand => switch (this) {
        AppColorTheme.red => const Color(0xFFC62828),
        AppColorTheme.orange => const Color(0xFFE65100),
        AppColorTheme.yellow => const Color(0xFFC9A000),
        AppColorTheme.ocean => const Color(0xFF0E5A8A),
        AppColorTheme.teal => const Color(0xFF116C71),
        AppColorTheme.violet => const Color(0xFF5E35B1),
        AppColorTheme.rose => const Color(0xFFC2185B),
        AppColorTheme.blossom => const Color(0xFFE91E8C),
        AppColorTheme.peony => const Color(0xFFAD4A72),
      };

  Color get highlight => switch (this) {
        AppColorTheme.red => const Color(0xFFFF5252),
        AppColorTheme.orange => const Color(0xFFFF9800),
        AppColorTheme.yellow => const Color(0xFFFFD54F),
        AppColorTheme.ocean => const Color(0xFF4FC3F7),
        AppColorTheme.teal => const Color(0xFFF15C22),
        AppColorTheme.violet => const Color(0xFFCE93D8),
        AppColorTheme.rose => const Color(0xFFFF80AB),
        AppColorTheme.blossom => const Color(0xFFFFB7D5),
        AppColorTheme.peony => const Color(0xFFF8BBD0),
      };

  Color get brandLight => switch (this) {
        AppColorTheme.red => const Color(0xFFE53935),
        AppColorTheme.orange => const Color(0xFFFF7043),
        AppColorTheme.yellow => const Color(0xFFF9A825),
        AppColorTheme.ocean => const Color(0xFF2F7FB5),
        AppColorTheme.teal => const Color(0xFF2A9AA3),
        AppColorTheme.violet => const Color(0xFF7E57C2),
        AppColorTheme.rose => const Color(0xFFEC407A),
        AppColorTheme.blossom => const Color(0xFFF06292),
        AppColorTheme.peony => const Color(0xFFCE6B96),
      };

  Color get gradientStart => switch (this) {
        AppColorTheme.red => const Color(0xFF5C1010),
        AppColorTheme.orange => const Color(0xFF4A2500),
        AppColorTheme.yellow => const Color(0xFF4A3800),
        AppColorTheme.ocean => const Color(0xFF083A5C),
        AppColorTheme.teal => const Color(0xFF0D3D42),
        AppColorTheme.violet => const Color(0xFF2D1B4E),
        AppColorTheme.rose => const Color(0xFF5A1230),
        AppColorTheme.blossom => const Color(0xFF5A1A42),
        AppColorTheme.peony => const Color(0xFF4A1A34),
      };

  Color get gradientEnd => switch (this) {
        AppColorTheme.red => const Color(0xFF8B1A1A),
        AppColorTheme.orange => const Color(0xFF7A3A00),
        AppColorTheme.yellow => const Color(0xFF7A5C00),
        AppColorTheme.ocean => const Color(0xFF0A4A72),
        AppColorTheme.teal => const Color(0xFF0A555C),
        AppColorTheme.violet => const Color(0xFF4527A0),
        AppColorTheme.rose => const Color(0xFF8E2450),
        AppColorTheme.blossom => const Color(0xFF8E2D62),
        AppColorTheme.peony => const Color(0xFF7A3558),
      };

  /// Soft header / card gradients in light mode for floral packs.
  Color get floralGradientStartLight => switch (this) {
        AppColorTheme.rose => const Color(0xFFFFE4EE),
        AppColorTheme.blossom => const Color(0xFFFFE8F4),
        AppColorTheme.peony => const Color(0xFFFFE6F0),
        _ => const Color(0xFFFFFFFF),
      };

  Color get floralGradientEndLight => switch (this) {
        AppColorTheme.rose => const Color(0xFFFFB8D2),
        AppColorTheme.blossom => const Color(0xFFFFC4E0),
        AppColorTheme.peony => const Color(0xFFFFBFD6),
        _ => brand,
      };

  List<Color> floralBackdrop(bool dark) => switch (this) {
        AppColorTheme.rose => dark
            ? [const Color(0xFF1A0C12), const Color(0xFF2A101C)]
            : [const Color(0xFFFFF5F8), const Color(0xFFFFE8F0)],
        AppColorTheme.blossom => dark
            ? [const Color(0xFF180D16), const Color(0xFF281422)]
            : [const Color(0xFFFFF7FB), const Color(0xFFFFECF4)],
        AppColorTheme.peony => dark
            ? [const Color(0xFF160E14), const Color(0xFF26131D)]
            : [const Color(0xFFFFF6FA), const Color(0xFFFFEAF2)],
        _ => dark
            ? [const Color(0xFF0C1415), const Color(0xFF152224)]
            : [const Color(0xFFFFFFFF), const Color(0xFFEFF5F5)],
      };

  Color floralSurface(bool dark) => switch (this) {
        AppColorTheme.rose =>
          dark ? const Color(0xFF1E1218) : const Color(0xFFFFF8FA),
        AppColorTheme.blossom =>
          dark ? const Color(0xFF1C1119) : const Color(0xFFFFFAFC),
        AppColorTheme.peony =>
          dark ? const Color(0xFF1A1016) : const Color(0xFFFFFAFB),
        _ => dark ? const Color(0xFF0C1415) : const Color(0xFFFFFFFF),
      };

  Color floralSurfaceVariant(bool dark) => switch (this) {
        AppColorTheme.rose =>
          dark ? const Color(0xFF2A1822) : const Color(0xFFFFEEF4),
        AppColorTheme.blossom =>
          dark ? const Color(0xFF281624) : const Color(0xFFFFF0F6),
        AppColorTheme.peony =>
          dark ? const Color(0xFF261420) : const Color(0xFFFFEFF5),
        _ => dark ? const Color(0xFF152224) : const Color(0xFFEFF5F5),
      };

  Color floralCard(bool dark) => switch (this) {
        AppColorTheme.rose =>
          dark ? const Color(0xFF24141C) : const Color(0xFFFFFCFD),
        AppColorTheme.blossom =>
          dark ? const Color(0xFF22131E) : const Color(0xFFFFFCFD),
        AppColorTheme.peony =>
          dark ? const Color(0xFF20121A) : const Color(0xFFFFFCFD),
        _ => dark ? const Color(0xFF1A2628) : const Color(0xFFFFFFFF),
      };
}

enum FloralMotif { none, rose, blossom, peony }
