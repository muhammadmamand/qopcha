import 'package:flutter/material.dart';

/// User-selectable brand color packs (independent of light/dark mode).
enum AppColorTheme {
  qopcha,
  ocean,
  forest,
  ember,
  midnight,
  sand,
  aurora,
  graphite,
  arctic,
  citrus;

  String get labelKu => switch (this) {
        AppColorTheme.qopcha => 'قۆپچە',
        AppColorTheme.ocean => 'زەریا',
        AppColorTheme.forest => 'دارستان',
        AppColorTheme.ember => 'گەرم',
        AppColorTheme.midnight => 'شەوی شین',
        AppColorTheme.sand => 'خۆڵەمێشی',
        AppColorTheme.aurora => 'ئۆرۆرا',
        AppColorTheme.graphite => 'گرافایت',
        AppColorTheme.arctic => 'ئەرکتیک',
        AppColorTheme.citrus => 'ترشەو',
      };

  String get subtitleKu => switch (this) {
        AppColorTheme.qopcha => 'تیڵ و پڕتەقاڵی — بنەڕەتی',
        AppColorTheme.ocean => 'شینی قووڵ و کۆراڵ',
        AppColorTheme.forest => 'سەوز و که‌هرەبایی',
        AppColorTheme.ember => 'گەرمی و ئۆرەنجی',
        AppColorTheme.midnight => 'شین تاریک و زێڕین',
        AppColorTheme.sand => 'زەیتوونی و تێراکۆتا',
        AppColorTheme.aurora => 'تیڵی درەوشاوە و مەرجان',
        AppColorTheme.graphite => 'ڕەشەتیرە و تیڵی کارەبا',
        AppColorTheme.arctic => 'شینی سارد و سەهۆڵ',
        AppColorTheme.citrus => 'سەوزی تازە و مەنگۆ',
      };

  Color get brand => switch (this) {
        AppColorTheme.qopcha => const Color(0xFF116C71),
        AppColorTheme.ocean => const Color(0xFF0E5A8A),
        AppColorTheme.forest => const Color(0xFF1B6B4A),
        AppColorTheme.ember => const Color(0xFF2C4A52),
        AppColorTheme.midnight => const Color(0xFF1A2B4A),
        AppColorTheme.sand => const Color(0xFF5C6B4A),
        AppColorTheme.aurora => const Color(0xFF0F766E),
        AppColorTheme.graphite => const Color(0xFF2F3437),
        AppColorTheme.arctic => const Color(0xFF2F6F8F),
        AppColorTheme.citrus => const Color(0xFF2F6B3A),
      };

  Color get highlight => switch (this) {
        AppColorTheme.qopcha => const Color(0xFFF15C22),
        AppColorTheme.ocean => const Color(0xFFE85D4C),
        AppColorTheme.forest => const Color(0xFFE09B2D),
        AppColorTheme.ember => const Color(0xFFF0783C),
        AppColorTheme.midnight => const Color(0xFFC9A87C),
        AppColorTheme.sand => const Color(0xFFC46B3A),
        AppColorTheme.aurora => const Color(0xFFFF6B57),
        AppColorTheme.graphite => const Color(0xFF00B4A6),
        AppColorTheme.arctic => const Color(0xFF5EC8C5),
        AppColorTheme.citrus => const Color(0xFFF4A261),
      };

  Color get brandLight => switch (this) {
        AppColorTheme.qopcha => const Color(0xFF2A9AA3),
        AppColorTheme.ocean => const Color(0xFF2F7FB5),
        AppColorTheme.forest => const Color(0xFF2F8F66),
        AppColorTheme.ember => const Color(0xFF4A6B74),
        AppColorTheme.midnight => const Color(0xFF3A4F78),
        AppColorTheme.sand => const Color(0xFF7A8B62),
        AppColorTheme.aurora => const Color(0xFF2A9B92),
        AppColorTheme.graphite => const Color(0xFF4A5256),
        AppColorTheme.arctic => const Color(0xFF4A8BA8),
        AppColorTheme.citrus => const Color(0xFF4A8B55),
      };

  Color get gradientStart => switch (this) {
        AppColorTheme.qopcha => const Color(0xFF0D3D42),
        AppColorTheme.ocean => const Color(0xFF083A5C),
        AppColorTheme.forest => const Color(0xFF0F3D2A),
        AppColorTheme.ember => const Color(0xFF1A3036),
        AppColorTheme.midnight => const Color(0xFF0F1729),
        AppColorTheme.sand => const Color(0xFF3A422E),
        AppColorTheme.aurora => const Color(0xFF0A4541),
        AppColorTheme.graphite => const Color(0xFF1A1E20),
        AppColorTheme.arctic => const Color(0xFF1A4054),
        AppColorTheme.citrus => const Color(0xFF1A3D22),
      };

  Color get gradientEnd => switch (this) {
        AppColorTheme.qopcha => const Color(0xFF0A555C),
        AppColorTheme.ocean => const Color(0xFF0A4A72),
        AppColorTheme.forest => const Color(0xFF145A3C),
        AppColorTheme.ember => const Color(0xFF243F46),
        AppColorTheme.midnight => const Color(0xFF162238),
        AppColorTheme.sand => const Color(0xFF4A5638),
        AppColorTheme.aurora => const Color(0xFF0D5C56),
        AppColorTheme.graphite => const Color(0xFF2A3033),
        AppColorTheme.arctic => const Color(0xFF275A72),
        AppColorTheme.citrus => const Color(0xFF275A32),
      };
}
