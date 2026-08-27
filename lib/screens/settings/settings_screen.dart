import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_color_theme.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_content_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/spatial_ui.dart';
import '../../widgets/telegram_theme_reveal.dart';

typedef _GlassBox = SpatialGlass;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static bool _isDarkMode(ThemeMode mode, Brightness platform) {
    return switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platform == Brightness.dark,
    };
  }

  Future<void> _switchTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode next,
  ) async {
    final current = ref.read(appSettingsProvider).themeMode;
    if (current == next) return;

    final platform = MediaQuery.platformBrightnessOf(context);
    final wasDark = _isDarkMode(current, platform);
    final willBeDark = _isDarkMode(next, platform);

    // Same effective brightness (e.g. system→light while already light).
    if (wasDark == willBeDark) {
      await ref.read(appSettingsProvider.notifier).setThemeMode(next);
      return;
    }

    final center = TelegramThemeReveal.centerFrom(context);
    final reveal = TelegramThemeReveal.of(context);
    if (reveal == null) {
      await ref.read(appSettingsProvider.notifier).setThemeMode(next);
      return;
    }

    await reveal.reveal(
      center: center,
      reverse: wasDark && !willBeDark,
      onThemeChange: () {
        ref.read(appSettingsProvider.notifier).setThemeMode(next);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: SpatialScene.backgroundColor,
      body: SpatialScene(
        child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 72,
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 76,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.pop(),
                  customBorder: const CircleBorder(),
                  child: _GlassBox(
                    shape: BoxShape.circle,
                    float: true,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'ڕێکخستنەکان',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ڕووکار، ئاگاداری و تایبەتمەندییەکان',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                _SectionTitle(icon: Icons.palette_outlined, title: 'ڕووکار'),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: _AppearancePanel(
                    themeMode: settings.themeMode,
                    colorTheme: settings.colorTheme,
                    onThemeMode: (ctx, mode) => _switchTheme(ctx, ref, mode),
                    onColorTheme: notifier.setColorTheme,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 28),
                _SectionTitle(icon: Icons.translate_rounded, title: 'زمان'),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: _LanguagePicker(
                    selected: settings.language,
                    onChanged: notifier.setLanguage,
                  ),
                ).animate().fadeIn(delay: 80.ms),
                const SizedBox(height: 28),
                _SectionTitle(
                  icon: Icons.notifications_none_rounded,
                  title: 'ئاگادارییەکان',
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: _NotificationsPanel(
                    masterEnabled: settings.notificationsEnabled,
                    notifyDiscounts: settings.notifyDiscounts,
                    notifyNewProducts: settings.notifyNewProducts,
                    notifyAppUpdates: settings.notifyAppUpdates,
                    onMasterChanged: notifier.setNotifications,
                    onDiscountsChanged: notifier.setNotifyDiscounts,
                    onNewProductsChanged: notifier.setNotifyNewProducts,
                    onAppUpdatesChanged: notifier.setNotifyAppUpdates,
                  ),
                ).animate().fadeIn(delay: 140.ms),
                const SizedBox(height: 28),
                _SectionTitle(
                  icon: Icons.info_outline_rounded,
                  title: 'دەربارەی ئەپ',
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: Column(
                    children: [
                      const _AboutTile(),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      _LegalLinkTile(
                        icon: Icons.info_outline_rounded,
                        title: 'دەربارەی ئێمە',
                        onTap: () => _openLegalSheet(
                          context,
                          ref,
                          title: 'دەربارەی ئێمە',
                          bodySelector: (c) => c.aboutBody,
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      _LegalLinkTile(
                        icon: Icons.gavel_outlined,
                        title: 'مەرجەکان',
                        onTap: () => _openLegalSheet(
                          context,
                          ref,
                          title: 'مەرجەکان',
                          bodySelector: (c) => c.termsBody,
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      _LegalLinkTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'سیاسەتی پاراستن',
                        onTap: () => _openLegalSheet(
                          context,
                          ref,
                          title: 'سیاسەتی پاراستن',
                          bodySelector: (c) => c.privacyBody,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ]),
            ),
          ),
        ],
          ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          _GlassBox(
            width: 34,
            height: 34,
            radius: 12,
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppColors.brand),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      float: true,
      radius: 36,
      padding: const EdgeInsets.all(22),
      child: child,
    );
  }
}

class _AppearancePanel extends StatelessWidget {
  final ThemeMode themeMode;
  final AppColorTheme colorTheme;
  final void Function(BuildContext context, ThemeMode mode) onThemeMode;
  final ValueChanged<AppColorTheme> onColorTheme;

  const _AppearancePanel({
    required this.themeMode,
    required this.colorTheme,
    required this.onThemeMode,
    required this.onColorTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'دۆخی ڕووناکی',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _ThemeModePicker(selected: themeMode, onChanged: onThemeMode),
        const SizedBox(height: 18),
        Text(
          'ڕەنگی ئەپ',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _ColorThemePicker(selected: colorTheme, onChanged: onColorTheme),
      ],
    );
  }
}

class _ThemeModePicker extends StatelessWidget {
  final ThemeMode selected;
  final void Function(BuildContext context, ThemeMode mode) onChanged;

  const _ThemeModePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = <(ThemeMode, IconData, String)>[
      (ThemeMode.system, Icons.brightness_auto_rounded, 'سیستەم'),
      (ThemeMode.light, Icons.wb_sunny_outlined, 'ڕووناک'),
      (ThemeMode.dark, Icons.nightlight_round, 'تاریک'),
    ];

    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Builder(
              builder: (btnContext) {
                final option = options[i];
                final isSelected = selected == option.$1;
                return GestureDetector(
                  onTap: () => onChanged(btnContext, option.$1),
                  child: _GlassBox(
                    selected: isSelected,
                    radius: 22,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      children: [
                        Icon(
                          option.$2,
                          size: 22,
                          color: isSelected
                              ? AppColors.brand
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          option.$3,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.brand
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ColorThemePicker extends StatelessWidget {
  final AppColorTheme selected;
  final ValueChanged<AppColorTheme> onChanged;

  const _ColorThemePicker({
    required this.selected,
    required this.onChanged,
  });

  static const double _ball = 34;
  static const double _gap = 12;
  static const double _ringPad = 5;

  @override
  Widget build(BuildContext context) {
    final themes = AppColorTheme.values;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = ((constraints.maxWidth + _gap) / (_ball + _gap))
            .floor()
            .clamp(1, themes.length);
        final rows = (themes.length / perRow).ceil();
        final index = themes.indexOf(selected).clamp(0, themes.length - 1);
        final row = index ~/ perRow;
        final col = index % perRow;
        final dx = col * (_ball + _gap);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: rows * (_ball + _gap) - _gap + _ringPad * 2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Jumping active ring (no hit testing — avoids layout crash)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    left: isRtl ? null : dx,
                    right: isRtl ? dx : null,
                    top: row * (_ball + _gap),
                    width: _ball + _ringPad * 2,
                    height: _ball + _ringPad * 2,
                    child: IgnorePointer(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected.brand,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Theme balls
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(_ringPad),
                      child: Wrap(
                        spacing: _gap,
                        runSpacing: _gap,
                        children: [
                          for (final theme in themes)
                            GestureDetector(
                              onTap: () => onChanged(theme),
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                width: _ball,
                                height: _ball,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.brand,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.brand.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(4, 4),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: AppColors.isDark ? 0.08 : 0.7,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(-3, -3),
                                      ),
                                    ],
                                  ),
                                  child: theme == selected
                                      ? Center(
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              selected.labelKu,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onChanged;

  const _LanguagePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LanguageOption(
          title: 'کوردی',
          subtitle: 'Kurdish · RTL',
          flag: 'KU',
          selected: selected == AppLanguage.kurdish,
          onTap: () => onChanged(AppLanguage.kurdish),
        ),
        const SizedBox(height: 10),
        _LanguageOption(
          title: 'English',
          subtitle: 'ئینگلیزی · LTR',
          flag: 'EN',
          selected: selected == AppLanguage.english,
          onTap: () => onChanged(AppLanguage.english),
        ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _GlassBox(
        selected: selected,
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _GlassBox(
              width: 44,
              height: 44,
              radius: 16,
              selected: selected,
              alignment: Alignment.center,
              child: Text(
                flag,
                style: TextStyle(
                  color: selected ? AppColors.brand : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: selected
                            ? AppColors.secondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.secondary,
                  size: 22,
                ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsPanel extends StatelessWidget {
  final bool masterEnabled;
  final bool notifyDiscounts;
  final bool notifyNewProducts;
  final bool notifyAppUpdates;
  final ValueChanged<bool> onMasterChanged;
  final ValueChanged<bool> onDiscountsChanged;
  final ValueChanged<bool> onNewProductsChanged;
  final ValueChanged<bool> onAppUpdatesChanged;

  const _NotificationsPanel({
    required this.masterEnabled,
    required this.notifyDiscounts,
    required this.notifyNewProducts,
    required this.notifyAppUpdates,
    required this.onMasterChanged,
    required this.onDiscountsChanged,
    required this.onNewProductsChanged,
    required this.onAppUpdatesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NotificationMasterTile(
          enabled: masterEnabled,
          onChanged: onMasterChanged,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: masterEnabled
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      'جۆری ئاگادارییەکان',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _NotificationChannelTile(
                      icon: Icons.percent_rounded,
                      title: 'داشکاندن و ئۆفەر',
                      subtitle: 'کاتێک داشکاندن یان پرۆمۆ هەیە',
                      enabled: notifyDiscounts,
                      onChanged: onDiscountsChanged,
                    ),
                    const SizedBox(height: 8),
                    _NotificationChannelTile(
                      icon: Icons.new_releases_outlined,
                      title: 'بەرهەمی نوێ',
                      subtitle: 'کاتێک دووکان کاڵای نوێ زیاد دەکات',
                      enabled: notifyNewProducts,
                      onChanged: onNewProductsChanged,
                    ),
                    const SizedBox(height: 8),
                    _NotificationChannelTile(
                      icon: Icons.system_update_alt_rounded,
                      title: 'نوێکاری ئەپ',
                      subtitle: 'گۆڕانکاری، نوێکاری و ئاگاداری سیستەم',
                      enabled: notifyAppUpdates,
                      onChanged: onAppUpdatesChanged,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _NotificationMasterTile extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationMasterTile({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassBox(
          width: 48,
          height: 48,
          radius: 16,
          alignment: Alignment.center,
          child: Icon(
            enabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_outlined,
            color: enabled ? AppColors.brand : AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هەموو ئاگادارییەکان',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                enabled
                    ? 'ئاگادارییەکان چالاکن — جۆرەکان لە خوارەوە'
                    : 'هەموو ئاگادارییەکان ناچالاک کراون',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        _GlassSwitch(value: enabled, onChanged: onChanged),
      ],
    );
  }
}

class _NotificationChannelTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationChannelTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      selected: enabled,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          _GlassBox(
            width: 40,
            height: 40,
            radius: 14,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.brand : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _GlassSwitch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

Future<void> _openLegalSheet(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String Function(AppContentModel content) bodySelector,
}) async {
  final content = ref.read(resolvedAppContentProvider);
  final body = bodySelector(content);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: _GlassBox(
            float: true,
            radius: 36,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: AppColors.isDark ? 0.28 : 0.55,
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      body,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.5,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      );
    },
  );
}

class _LegalLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LegalLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _GlassBox(
              width: 42,
              height: 42,
              radius: 14,
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.brand, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _GlassBox(
              width: 32,
              height: 32,
              shape: BoxShape.circle,
              alignment: Alignment.center,
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends ConsumerWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagline = ref.watch(resolvedAppContentProvider).homeTagline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _GlassBox(
            width: 46,
            height: 46,
            radius: 16,
            selected: true,
            alignment: Alignment.center,
            child: Icon(
              Icons.checkroom_rounded,
              color: AppColors.brand,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tagline.isEmpty
                      ? 'Version 1.0.0 · Clothing marketplace'
                      : tagline,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GlassSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          color: value
              ? AppColors.brand.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: dark ? 0.12 : 0.28),
          border: Border.all(
            color: Colors.white.withValues(alpha: dark ? 0.28 : 0.65),
            width: 0.8,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.92),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
