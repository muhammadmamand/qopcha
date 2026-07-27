import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { kurdish, english }

class AppSettingsState {
  final ThemeMode themeMode;
  final AppLanguage language;
  final bool notificationsEnabled;
  final bool isLoaded;

  const AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.kurdish,
    this.notificationsEnabled = true,
    this.isLoaded = false,
  });

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    bool? notificationsEnabled,
    bool? isLoaded,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier() : super(const AppSettingsState()) {
    _load();
  }

  static const _themeKey = 'settings_theme_mode';
  static const _languageKey = 'settings_language';
  static const _notificationsKey = 'settings_notifications';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    final lang = prefs.getString(_languageKey);
    final notifications = prefs.getBool(_notificationsKey);

    state = state.copyWith(
      themeMode: themeIndex == null
          ? ThemeMode.system
          : ThemeMode.values[themeIndex],
      language: lang == 'en' ? AppLanguage.english : AppLanguage.kurdish,
      notificationsEnabled: notifications ?? true,
      isLoaded: true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language == AppLanguage.english ? 'en' : 'ku');
  }

  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier();
});
