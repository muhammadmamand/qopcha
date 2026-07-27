import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 148,
            backgroundColor: AppColors.gradientMid,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(72, 18, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'ڕێکخستنەکان',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ڕووکار، زمان و ئاگادارییەکان',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle(icon: Icons.palette_outlined, title: 'ڕووکار'),
                const SizedBox(height: 10),
                _SettingsCard(
                  child: _ThemePicker(
                    selected: settings.themeMode,
                    onChanged: notifier.setThemeMode,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                const SizedBox(height: 22),
                _SectionTitle(icon: Icons.translate_rounded, title: 'زمان'),
                const SizedBox(height: 10),
                _SettingsCard(
                  child: _LanguagePicker(
                    selected: settings.language,
                    onChanged: notifier.setLanguage,
                  ),
                ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.05),
                const SizedBox(height: 22),
                _SectionTitle(
                  icon: Icons.notifications_none_rounded,
                  title: 'ئاگادارییەکان',
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  child: _NotificationTile(
                    enabled: settings.notificationsEnabled,
                    onChanged: notifier.setNotifications,
                  ),
                ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.05),
                const SizedBox(height: 22),
                _SectionTitle(
                  icon: Icons.slideshow_rounded,
                  title: 'سلایدەر',
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  child: _OnboardingReplayTile(
                    onTap: () => context.push('/onboarding'),
                  ),
                ).animate().fadeIn(delay: 170.ms).slideY(begin: 0.05),
                const SizedBox(height: 22),
                _SectionTitle(
                  icon: Icons.info_outline_rounded,
                  title: 'دەربارەی ئەپ',
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  child: const _AboutTile(),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
              ]),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: 24),
      child: child,
    );
  }
}

class _ThemePicker extends StatelessWidget {
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        ThemeMode.system,
        Icons.settings_suggest_outlined,
        'سیستەم',
        'وەک ئامێرەکە',
      ),
      (ThemeMode.light, Icons.light_mode_outlined, 'ڕووناک', 'ڕووکاری سپێ'),
      (ThemeMode.dark, Icons.dark_mode_outlined, 'تاریک', 'ڕووکاری شەو'),
    ];

    return Row(
      children: options.map((option) {
        final isSelected = selected == option.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              end: option.$1 == ThemeMode.dark ? 0 : 8,
            ),
            child: Material(
              color: isSelected
                  ? AppColors.secondary.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => onChanged(option.$1),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.secondary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        option.$2,
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option.$3,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.$4,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
    return Material(
      color: selected
          ? AppColors.secondary.withValues(alpha: 0.08)
          : AppColors.surfaceVariant.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.secondary : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.secondary : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  flag,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
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
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.secondary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            enabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_outlined,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'وەرگرتنی ئاگاداری',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'ئۆفەر و نوێکارییەکان وەربگرە',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: enabled,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.secondary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _OnboardingReplayTile extends StatelessWidget {
  final VoidCallback onTap;

  const _OnboardingReplayTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.view_carousel_rounded,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بینینی سلایدەری دەستپێک',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'دووبارە پیشاندانی ئۆنۆبۆردینگ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.checkroom_rounded,
            color: Colors.white,
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
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Version 1.0.0 · Clothing marketplace',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
