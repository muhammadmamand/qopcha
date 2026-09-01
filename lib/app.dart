import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/platform/app_host.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'widgets/app_colors_theme_binder.dart';
import 'widgets/telegram_theme_reveal.dart';

class QopchaApp extends ConsumerWidget {
  const QopchaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsProvider);
    final locale = settings.language == AppLanguage.english
        ? const Locale('en')
        : const Locale('ar');
    final textDirection = settings.language.textDirection;

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    // Admin web console is always light — cleaner ERP look.
    final effectiveBrightness = AppHost.isAdminWebConsole
        ? Brightness.light
        : switch (settings.themeMode) {
            ThemeMode.light => Brightness.light,
            ThemeMode.dark => Brightness.dark,
            ThemeMode.system => platformBrightness,
          };
    AppColors.applyColorTheme(settings.colorTheme);
    AppColors.applyBrightness(effectiveBrightness);

    final appTitle = AppHost.isAdminWebConsole
        ? '${AppConstants.appNameEn} | Admin'
        : AppConstants.windowBrandTitle;

    return MaterialApp.router(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          AppHost.isAdminWebConsole ? ThemeMode.light : settings.themeMode,
      // Circular wipe owns the light/dark transition on mobile.
      themeAnimationDuration: Duration.zero,
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        final content = Directionality(
          textDirection: textDirection,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
              decorationThickness: 0,
            ),
            child: AppColorsThemeBinder(
              colorTheme: settings.colorTheme,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
        // Snapshot theme wipe uses dart:ui Image and breaks Flutter Web hot restart
        // (disposed EngineFlutterView). Keep it on mobile/desktop only.
        if (AppHost.isWeb) return content;
        return TelegramThemeReveal(child: content);
      },
    );
  }
}
