import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

class LanguageSwitcherButton extends ConsumerWidget {
  final bool onDark;

  const LanguageSwitcherButton({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appSettingsProvider.select((s) => s.language));
    final label = switch (lang) {
      AppLanguage.english => 'EN',
      AppLanguage.arabic => 'AR',
      AppLanguage.kurdish => 'KU',
    };
    final fg = onDark ? Colors.white : AppColors.brand;
    final bg = onDark
        ? Colors.white.withValues(alpha: 0.16)
        : AppColors.brand.withValues(alpha: 0.10);
    final border = onDark
        ? Colors.white.withValues(alpha: 0.28)
        : AppColors.brand.withValues(alpha: 0.18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showLanguagePickerSheet(context, ref),
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate_rounded, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showLanguagePickerSheet(BuildContext context, WidgetRef ref) {
  HapticFeedback.selectionClick();
  final selected = ref.read(appSettingsProvider).language;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          22,
          16,
          22,
          18 + MediaQuery.paddingOf(ctx).bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.sheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr(selected, 'زمان', 'Language', 'اللغة'),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                selected,
                'دەتوانیت زمان بگۆڕیت بەبێ چوونەژوورەوە',
                'You can change language without logging in',
                'يمكنك تغيير اللغة دون تسجيل الدخول',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            _LangTile(
              code: 'KU',
              title: 'کوردی',
              subtitle: 'Kurdish · Sorani',
              selected: selected == AppLanguage.kurdish,
              onTap: () => _pick(ctx, ref, AppLanguage.kurdish),
            ),
            const SizedBox(height: 8),
            _LangTile(
              code: 'AR',
              title: 'العربية',
              subtitle: 'Arabic',
              selected: selected == AppLanguage.arabic,
              onTap: () => _pick(ctx, ref, AppLanguage.arabic),
            ),
            const SizedBox(height: 8),
            _LangTile(
              code: 'EN',
              title: 'English',
              subtitle: 'English',
              selected: selected == AppLanguage.english,
              onTap: () => _pick(ctx, ref, AppLanguage.english),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _pick(
  BuildContext context,
  WidgetRef ref,
  AppLanguage language,
) async {
  HapticFeedback.selectionClick();
  await ref.read(appSettingsProvider.notifier).setLanguage(language);
  if (context.mounted) Navigator.of(context).pop();
}

class _LangTile extends StatelessWidget {
  final String code;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.brand.withValues(alpha: 0.10)
          : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.brand : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: selected ? Colors.white : AppColors.textPrimary,
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
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: AppColors.brand),
            ],
          ),
        ),
      ),
    );
  }
}
