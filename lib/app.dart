import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';

class ShikPoshApp extends ConsumerWidget {
  const ShikPoshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsProvider);
    final locale = settings.language == AppLanguage.english
        ? const Locale('en')
        : const Locale('ku');
    final textDirection = settings.language == AppLanguage.english
        ? TextDirection.ltr
        : TextDirection.rtl;

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final effectiveBrightness = switch (settings.themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platformBrightness,
    };
    AppColors.applyBrightness(effectiveBrightness);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: locale,
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: textDirection,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
              decorationThickness: 0,
            ),
            child: child!,
          ),
        );
      },
    );
  }
}
