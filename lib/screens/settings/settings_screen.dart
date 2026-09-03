import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_color_theme.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/liquid_glass_settings_switch.dart';
import 'legal_document_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _switchTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode next,
  ) async {
    final current = ref.read(appSettingsProvider).themeMode;
    if (current == next) return;

    // Instant switch on settings — the full-app snapshot wipe is heavy and
    // drops taps while _busy, which feels laggy with 3 mode buttons.
    await ref.read(appSettingsProvider.notifier).setThemeMode(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldFill,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                _BackButton(onTap: () => context.pop()),
                const Spacer(),
              ],
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 18),
            Text(
              s.settings,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.settingsSubtitle,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(icon: Icons.palette_outlined, title: s.appearance),
            const SizedBox(height: 10),
            _SettingsCard(
                  child: _AppearancePanel(
                    themeMode: settings.themeMode,
                    colorTheme: settings.colorTheme,
                    brightnessLabel: s.brightnessMode,
                    appColorLabel: s.appColor,
                    themeSystem: s.themeSystem,
                    themeLight: s.themeLight,
                    themeDark: s.themeDark,
                    colorThemeLabelOf: s.colorThemeLabel,
                    onThemeMode: (ctx, mode) => _switchTheme(ctx, ref, mode),
                    onColorTheme: notifier.setColorTheme,
                  ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 22),
            _SectionTitle(icon: Icons.translate_rounded, title: s.language),
            const SizedBox(height: 10),
            _SettingsCard(
                  child: _LanguagePicker(
                    selected: settings.language,
                    kurdish: s.kurdish,
                    kurdishSubtitle: s.kurdishSubtitle,
                    arabic: s.arabic,
                    arabicSubtitle: s.arabicSubtitle,
                    english: s.english,
                    englishSubtitle: s.englishSubtitle,
                    onChanged: notifier.setLanguage,
                  ),
            ).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 22),
            _SectionTitle(
              icon: Icons.notifications_none_rounded,
              title: s.notifications,
            ),
            const SizedBox(height: 10),
            _SettingsCard(
                  child: _NotificationsPanel(
                    masterEnabled: settings.notificationsEnabled,
                    notifyDiscounts: settings.notifyDiscounts,
                    notifyNewProducts: settings.notifyNewProducts,
                    notifyAppUpdates: settings.notifyAppUpdates,
                    notificationTypes: s.notificationTypes,
                    allNotifications: s.allNotifications,
                    notificationsOn: s.notificationsOn,
                    notificationsOff: s.notificationsOff,
                    discountsTitle: s.notifyDiscounts,
                    discountsSub: s.notifyDiscountsSub,
                    newProductsTitle: s.notifyNewProducts,
                    newProductsSub: s.notifyNewProductsSub,
                    appUpdatesTitle: s.notifyAppUpdates,
                    appUpdatesSub: s.notifyAppUpdatesSub,
                    onMasterChanged: notifier.setNotifications,
                    onDiscountsChanged: notifier.setNotifyDiscounts,
                    onNewProductsChanged: notifier.setNotifyNewProducts,
                    onAppUpdatesChanged: notifier.setNotifyAppUpdates,
                  ),
            ).animate().fadeIn(delay: 140.ms),
            const SizedBox(height: 22),
            _SectionTitle(
              icon: Icons.info_outline_rounded,
              title: s.aboutApp,
            ),
            const SizedBox(height: 10),
            _SettingsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: _AboutTile(),
                  ),
                  _SettingsDivider(),
                  _LegalLinkTile(
                    icon: Icons.info_outline_rounded,
                    title: s.aboutUs,
                    onTap: () => context.push(LegalDocumentScreen.routeFor(
                      LegalDocumentKind.about,
                    )),
                  ),
                  _SettingsDivider(),
                  _LegalLinkTile(
                    icon: Icons.gavel_outlined,
                    title: s.terms,
                    onTap: () => context.push(LegalDocumentScreen.routeFor(
                      LegalDocumentKind.terms,
                    )),
                  ),
                  _SettingsDivider(),
                  _LegalLinkTile(
                    icon: Icons.privacy_tip_outlined,
                    title: s.privacyPolicy,
                    onTap: () => context.push(LegalDocumentScreen.routeFor(
                      LegalDocumentKind.privacy,
                    )),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: AppColors.border.withValues(alpha: 0.55),
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.brand),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
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
  final EdgeInsetsGeometry? padding;

  const _SettingsCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AppearancePanel extends StatelessWidget {
  final ThemeMode themeMode;
  final AppColorTheme colorTheme;
  final String brightnessLabel;
  final String appColorLabel;
  final String themeSystem;
  final String themeLight;
  final String themeDark;
  final String Function(AppColorTheme theme) colorThemeLabelOf;
  final void Function(BuildContext context, ThemeMode mode) onThemeMode;
  final ValueChanged<AppColorTheme> onColorTheme;

  const _AppearancePanel({
    required this.themeMode,
    required this.colorTheme,
    required this.brightnessLabel,
    required this.appColorLabel,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.colorThemeLabelOf,
    required this.onThemeMode,
    required this.onColorTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          brightnessLabel,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _ThemeModePicker(
          selected: themeMode,
          themeSystem: themeSystem,
          themeLight: themeLight,
          themeDark: themeDark,
          onChanged: onThemeMode,
        ),
        const SizedBox(height: 18),
        Text(
          appColorLabel,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _ColorThemePicker(
          selected: colorTheme,
          labelOf: colorThemeLabelOf,
          onChanged: onColorTheme,
        ),
      ],
    );
  }
}

class _ThemeModePicker extends StatelessWidget {
  final ThemeMode selected;
  final String themeSystem;
  final String themeLight;
  final String themeDark;
  final void Function(BuildContext context, ThemeMode mode) onChanged;

  const _ThemeModePicker({
    required this.selected,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = <(ThemeMode, IconData, String)>[
      (ThemeMode.system, Icons.brightness_auto_rounded, themeSystem),
      (ThemeMode.light, Icons.wb_sunny_outlined, themeLight),
      (ThemeMode.dark, Icons.nightlight_round, themeDark),
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
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(btnContext, option.$1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brand.withValues(alpha: 0.1)
                          : AppColors.surfaceVariant.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brand.withValues(alpha: 0.55)
                            : AppColors.border.withValues(alpha: 0.65),
                      ),
                    ),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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
  final String Function(AppColorTheme theme) labelOf;
  final ValueChanged<AppColorTheme> onChanged;

  const _ColorThemePicker({
    required this.selected,
    required this.labelOf,
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
                                  child: theme.isFloral
                                      ? Center(
                                          child: Icon(
                                            switch (theme.floralMotif) {
                                              FloralMotif.rose =>
                                                Icons.local_florist_rounded,
                                              FloralMotif.blossom =>
                                                Icons.filter_vintage_rounded,
                                              FloralMotif.peony =>
                                                Icons.spa_rounded,
                                              FloralMotif.none =>
                                                Icons.local_florist_outlined,
                                            },
                                            size: 16,
                                            color: Colors.white.withValues(
                                              alpha: 0.92,
                                            ),
                                          ),
                                        )
                                      : theme == selected
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
              labelOf(selected),
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
  final String kurdish;
  final String kurdishSubtitle;
  final String arabic;
  final String arabicSubtitle;
  final String english;
  final String englishSubtitle;
  final ValueChanged<AppLanguage> onChanged;

  const _LanguagePicker({
    required this.selected,
    required this.kurdish,
    required this.kurdishSubtitle,
    required this.arabic,
    required this.arabicSubtitle,
    required this.english,
    required this.englishSubtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LanguageOption(
          title: kurdish,
          subtitle: kurdishSubtitle,
          flag: 'KU',
          selected: selected == AppLanguage.kurdish,
          onTap: () => onChanged(AppLanguage.kurdish),
        ),
        const SizedBox(height: 10),
        _LanguageOption(
          title: arabic,
          subtitle: arabicSubtitle,
          flag: 'AR',
          selected: selected == AppLanguage.arabic,
          onTap: () => onChanged(AppLanguage.arabic),
        ),
        const SizedBox(height: 10),
        _LanguageOption(
          title: english,
          subtitle: englishSubtitle,
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
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brand.withValues(alpha: 0.08)
              : AppColors.surfaceVariant.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.brand.withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.brand.withValues(alpha: 0.14)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                flag,
                style: TextStyle(
                  color: selected ? AppColors.brand : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
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
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: selected
                          ? AppColors.brand
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.brand,
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
  final String notificationTypes;
  final String allNotifications;
  final String notificationsOn;
  final String notificationsOff;
  final String discountsTitle;
  final String discountsSub;
  final String newProductsTitle;
  final String newProductsSub;
  final String appUpdatesTitle;
  final String appUpdatesSub;
  final ValueChanged<bool> onMasterChanged;
  final ValueChanged<bool> onDiscountsChanged;
  final ValueChanged<bool> onNewProductsChanged;
  final ValueChanged<bool> onAppUpdatesChanged;

  const _NotificationsPanel({
    required this.masterEnabled,
    required this.notifyDiscounts,
    required this.notifyNewProducts,
    required this.notifyAppUpdates,
    required this.notificationTypes,
    required this.allNotifications,
    required this.notificationsOn,
    required this.notificationsOff,
    required this.discountsTitle,
    required this.discountsSub,
    required this.newProductsTitle,
    required this.newProductsSub,
    required this.appUpdatesTitle,
    required this.appUpdatesSub,
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
          title: allNotifications,
          subtitleOn: notificationsOn,
          subtitleOff: notificationsOff,
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
                      notificationTypes,
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
                      title: discountsTitle,
                      subtitle: discountsSub,
                      enabled: notifyDiscounts,
                      onChanged: onDiscountsChanged,
                    ),
                    const SizedBox(height: 8),
                    _NotificationChannelTile(
                      icon: Icons.new_releases_outlined,
                      title: newProductsTitle,
                      subtitle: newProductsSub,
                      enabled: notifyNewProducts,
                      onChanged: onNewProductsChanged,
                    ),
                    const SizedBox(height: 8),
                    _NotificationChannelTile(
                      icon: Icons.system_update_alt_rounded,
                      title: appUpdatesTitle,
                      subtitle: appUpdatesSub,
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
  final String title;
  final String subtitleOn;
  final String subtitleOff;
  final ValueChanged<bool> onChanged;

  const _NotificationMasterTile({
    required this.enabled,
    required this.title,
    required this.subtitleOn,
    required this.subtitleOff,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.brand.withValues(alpha: 0.12)
                : AppColors.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
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
                title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                enabled ? subtitleOn : subtitleOff,
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
        LiquidGlassSettingsSwitch(value: enabled, onChanged: onChanged),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.brand.withValues(alpha: 0.06)
            : AppColors.surfaceVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? AppColors.brand.withValues(alpha: 0.35)
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.brand.withValues(alpha: 0.12)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 19,
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
          LiquidGlassSettingsSwitch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.brand),
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
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
            ],
          ),
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
    final s = ref.watch(stringsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
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
                  tagline.isEmpty ? s.aboutVersionFallback : tagline,
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
        ],
      ),
    );
  }
}

