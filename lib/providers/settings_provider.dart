import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_color_theme.dart';

enum AppLanguage {
  kurdish,
  arabic,
  english;

  bool get isRtl => this != AppLanguage.english;

  String get code => switch (this) {
        AppLanguage.english => 'en',
        AppLanguage.arabic => 'ar',
        AppLanguage.kurdish => 'ku',
      };

  Locale get locale => Locale(code);

  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  static AppLanguage fromCode(String? code) {
    return switch (code) {
      'en' => AppLanguage.english,
      'ar' => AppLanguage.arabic,
      _ => AppLanguage.kurdish,
    };
  }
}

/// Kurdish / English / Arabic UI string.
String tr(AppLanguage lang, String ku, String en, String ar) {
  return switch (lang) {
    AppLanguage.english => en,
    AppLanguage.arabic => ar,
    AppLanguage.kurdish => ku,
  };
}

class AppSettingsState {
  final ThemeMode themeMode;
  final AppColorTheme colorTheme;
  final AppLanguage language;

  /// Master switch — when false, all notification channels are muted.
  final bool notificationsEnabled;

  /// Offers / product & delivery discounts.
  final bool notifyDiscounts;

  /// New products from shops.
  final bool notifyNewProducts;

  /// App updates, admin announcements, policy changes.
  final bool notifyAppUpdates;

  final bool isLoaded;

  const AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.colorTheme = AppColorTheme.teal,
    this.language = AppLanguage.kurdish,
    this.notificationsEnabled = true,
    this.notifyDiscounts = true,
    this.notifyNewProducts = true,
    this.notifyAppUpdates = true,
    this.isLoaded = false,
  });

  bool allowsNotificationType(String type, {String category = ''}) {
    if (!notificationsEnabled) return false;
    final cat = category.trim().toLowerCase();
    if (type == 'new_product') return notifyNewProducts;
    if (type == 'admin_announcement') {
      if (cat == 'discount' || cat == 'promo' || cat == 'offer') {
        return notifyDiscounts;
      }
      return notifyAppUpdates;
    }
    if (cat == 'discount' || cat == 'promo' || cat == 'offer') {
      return notifyDiscounts;
    }
    // Account / system notices follow app-updates preference.
    if (type == 'account_approved') return notifyAppUpdates;
    return true;
  }

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    AppColorTheme? colorTheme,
    AppLanguage? language,
    bool? notificationsEnabled,
    bool? notifyDiscounts,
    bool? notifyNewProducts,
    bool? notifyAppUpdates,
    bool? isLoaded,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      colorTheme: colorTheme ?? this.colorTheme,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyDiscounts: notifyDiscounts ?? this.notifyDiscounts,
      notifyNewProducts: notifyNewProducts ?? this.notifyNewProducts,
      notifyAppUpdates: notifyAppUpdates ?? this.notifyAppUpdates,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier() : super(const AppSettingsState()) {
    _load();
  }

  static const _themeKey = 'settings_theme_mode';
  static const _colorThemeKey = 'settings_color_theme';
  static const _languageKey = 'settings_language';
  static const _notificationsKey = 'settings_notifications';
  static const _notifyDiscountsKey = 'settings_notify_discounts';
  static const _notifyNewProductsKey = 'settings_notify_new_products';
  static const _notifyAppUpdatesKey = 'settings_notify_app_updates';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    final colorName = prefs.getString(_colorThemeKey);
    final lang = prefs.getString(_languageKey);

    var colorTheme = AppColorTheme.teal;
    if (colorName != null) {
      colorTheme = AppColorTheme.resolve(colorName);
    }

    state = state.copyWith(
      themeMode: themeIndex == null
          ? ThemeMode.system
          : ThemeMode.values[themeIndex],
      colorTheme: colorTheme,
      language: AppLanguage.fromCode(lang),
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      notifyDiscounts: prefs.getBool(_notifyDiscountsKey) ?? true,
      notifyNewProducts: prefs.getBool(_notifyNewProductsKey) ?? true,
      notifyAppUpdates: prefs.getBool(_notifyAppUpdatesKey) ?? true,
      isLoaded: true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setColorTheme(AppColorTheme theme) async {
    state = state.copyWith(colorTheme: theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorThemeKey, theme.name);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
  }

  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<void> setNotifyDiscounts(bool enabled) async {
    state = state.copyWith(notifyDiscounts: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifyDiscountsKey, enabled);
  }

  Future<void> setNotifyNewProducts(bool enabled) async {
    state = state.copyWith(notifyNewProducts: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifyNewProductsKey, enabled);
  }

  Future<void> setNotifyAppUpdates(bool enabled) async {
    state = state.copyWith(notifyAppUpdates: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifyAppUpdatesKey, enabled);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier();
});
