import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/legal_about_content.dart';
import '../../core/l10n/legal_privacy_content.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_content_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/spatial_ui.dart';

enum LegalDocumentKind { about, terms, privacy }

class LegalDocumentScreen extends ConsumerWidget {
  final LegalDocumentKind kind;

  const LegalDocumentScreen({super.key, required this.kind});

  static String routeFor(LegalDocumentKind kind) => switch (kind) {
        LegalDocumentKind.about => '/legal/about',
        LegalDocumentKind.terms => '/legal/terms',
        LegalDocumentKind.privacy => '/legal/privacy',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(appSettingsProvider.select((st) => st.language));
    final content = ref.watch(resolvedAppContentProvider);
    final aboutContent = LegalAboutContent(lang);
    final title = switch (kind) {
      LegalDocumentKind.about => s.aboutUs,
      LegalDocumentKind.terms => s.terms,
      LegalDocumentKind.privacy => s.privacyPolicy,
    };
    final subtitle = switch (kind) {
      LegalDocumentKind.about => aboutContent.heroLead,
      LegalDocumentKind.terms => s.termsAppliesToAllUsers,
      LegalDocumentKind.privacy => LegalPrivacyContent(lang).heroLead,
    };
    final body = switch (kind) {
      LegalDocumentKind.about => content.aboutBody,
      LegalDocumentKind.terms => content.termsBody,
      LegalDocumentKind.privacy => content.privacyBody,
    };
    final fallback = _fallbackBody(s, kind);
    final useBuiltInAbout = kind == LegalDocumentKind.about &&
        !_hasCustomAboutBody(content.aboutBody);
    final useBuiltInPrivacy = kind == LegalDocumentKind.privacy &&
        !_hasCustomPrivacyBody(content.privacyBody);

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
                    child: SpatialGlass(
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
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _LegalHero(
                    kind: kind,
                    title: title,
                    subtitle: subtitle,
                    badges: switch (kind) {
                      LegalDocumentKind.privacy => [
                        LegalPrivacyContent(lang).badgeSecure,
                        LegalPrivacyContent(lang).badgeNoSell,
                      ],
                      LegalDocumentKind.about => [
                        aboutContent.badgeShoppers,
                        aboutContent.badgeShops,
                      ],
                      LegalDocumentKind.terms => null,
                    },
                  ),
                  const SizedBox(height: 22),
                  if (useBuiltInAbout)
                    _InAppAboutPage(
                      content: aboutContent,
                      supportEmail: _supportEmail(content),
                    )
                  else if (useBuiltInPrivacy)
                    _InAppPrivacyPolicy(
                      content: LegalPrivacyContent(lang),
                      supportEmail: _supportEmail(content),
                    )
                  else
                    _LegalTextCard(
                      text: body.trim().isNotEmpty ? body.trim() : fallback,
                    )
                        .animate()
                        .fadeIn(duration: AppAnimations.normal)
                        .slideY(
                          begin: 0.04,
                          curve: AppAnimations.smooth,
                        ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _hasCustomAboutBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return false;
    return trimmed != AppContentModel.defaults().aboutBody;
  }

  static bool _hasCustomPrivacyBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return false;
    return trimmed != AppContentModel.defaults().privacyBody;
  }

  static String _supportEmail(AppContentModel content) {
    final email = content.supportEmail.trim();
    if (email.isNotEmpty) return email;
    return AppContentModel.defaults().supportEmail;
  }

  static String _fallbackBody(AppStrings s, LegalDocumentKind kind) {
    return switch (kind) {
      LegalDocumentKind.about => s.aboutFallback,
      LegalDocumentKind.terms => s.termsFallback,
      LegalDocumentKind.privacy => s.privacyFallback,
    };
  }
}

class _LegalHero extends StatelessWidget {
  final LegalDocumentKind kind;
  final String title;
  final String subtitle;
  final List<String>? badges;

  const _LegalHero({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.badges,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      LegalDocumentKind.about => Icons.info_outline_rounded,
      LegalDocumentKind.terms => Icons.gavel_rounded,
      LegalDocumentKind.privacy => Icons.shield_outlined,
    };
    final accent = switch (kind) {
      LegalDocumentKind.about => AppColors.brand,
      LegalDocumentKind.terms => AppColors.highlight,
      LegalDocumentKind.privacy => AppColors.success,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -36,
                right: -28,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -16,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
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
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (badges != null && badges!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroBadge(
                          icon: Icons.lock_rounded,
                          label: badges![0],
                        ),
                        if (badges!.length > 1)
                          _HeroBadge(
                            icon: Icons.verified_user_outlined,
                            label: badges![1],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.smooth)
            .slideY(begin: -0.05, curve: AppAnimations.smooth),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalTextCard extends StatelessWidget {
  final String text;

  const _LegalTextCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return SpatialGlass(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 14.5,
          height: 1.65,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _InAppPrivacyPolicy extends StatelessWidget {
  final LegalPrivacyContent content;
  final String supportEmail;

  const _InAppPrivacyPolicy({
    required this.content,
    required this.supportEmail,
  });

  static const _sectionIcons = [
    Icons.inventory_2_outlined,
    Icons.tune_rounded,
    Icons.hub_outlined,
    Icons.security_rounded,
    Icons.touch_app_outlined,
    Icons.family_restroom_outlined,
  ];

  static final _sectionColors = [
    AppColors.brand,
    AppColors.highlight,
    AppColors.secondaryLight,
    AppColors.success,
    AppColors.brand,
    AppColors.highlight,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpatialGlass(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  size: 20,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  content.updated,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 60.ms, duration: AppAnimations.normal),
        const SizedBox(height: 12),
        SpatialGlass(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Text(
            content.intro,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.5,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: AppAnimations.normal)
            .slideY(begin: 0.03, curve: AppAnimations.smooth),
        const SizedBox(height: 18),
        ...content.sections.asMap().entries.map((entry) {
          final i = entry.key;
          final section = entry.value;
          final icon = _sectionIcons[i % _sectionIcons.length];
          final color = _sectionColors[i % _sectionColors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PrivacySectionCard(
              section: section,
              index: i + 1,
              icon: icon,
              accent: color,
            )
                .animate()
                .fadeIn(
                  delay: (140 + i * 50).ms,
                  duration: AppAnimations.normal,
                  curve: AppAnimations.smooth,
                )
                .slideY(
                  begin: 0.05,
                  delay: (140 + i * 50).ms,
                  duration: AppAnimations.normal,
                  curve: AppAnimations.smooth,
                ),
          );
        }),
        _ContactCard(
          title: content.contactTitle,
          body: content.contactBody(supportEmail),
          email: supportEmail,
        )
            .animate()
            .fadeIn(delay: 420.ms, duration: AppAnimations.normal)
            .slideY(begin: 0.04, curve: AppAnimations.smooth),
      ],
    );
  }
}

class _InAppAboutPage extends StatelessWidget {
  final LegalAboutContent content;
  final String supportEmail;

  const _InAppAboutPage({
    required this.content,
    required this.supportEmail,
  });

  static const _sectionIcons = [
    Icons.storefront_rounded,
    Icons.shopping_bag_outlined,
    Icons.store_mall_directory_outlined,
    Icons.favorite_outline_rounded,
    Icons.route_rounded,
    Icons.translate_rounded,
  ];

  static final _sectionColors = [
    AppColors.brand,
    AppColors.highlight,
    AppColors.secondaryLight,
    AppColors.success,
    AppColors.brand,
    AppColors.highlight,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpatialGlass(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Text(
            content.intro,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.5,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: AppAnimations.normal)
            .slideY(begin: 0.03, curve: AppAnimations.smooth),
        const SizedBox(height: 18),
        ...content.sections.asMap().entries.map((entry) {
          final i = entry.key;
          final section = entry.value;
          final icon = _sectionIcons[i % _sectionIcons.length];
          final color = _sectionColors[i % _sectionColors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PrivacySectionCard(
              section: section,
              index: i + 1,
              icon: icon,
              accent: color,
            )
                .animate()
                .fadeIn(
                  delay: (140 + i * 50).ms,
                  duration: AppAnimations.normal,
                  curve: AppAnimations.smooth,
                )
                .slideY(
                  begin: 0.05,
                  delay: (140 + i * 50).ms,
                  duration: AppAnimations.normal,
                  curve: AppAnimations.smooth,
                ),
          );
        }),
        _ContactCard(
          title: content.contactTitle,
          body: content.contactBody(supportEmail),
          email: supportEmail,
        )
            .animate()
            .fadeIn(delay: 420.ms, duration: AppAnimations.normal)
            .slideY(begin: 0.04, curve: AppAnimations.smooth),
      ],
    );
  }
}

class _PrivacySectionCard extends StatelessWidget {
  final LegalSection section;
  final int index;
  final IconData icon;
  final Color accent;

  const _PrivacySectionCard({
    required this.section,
    required this.index,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SpatialGlass(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.18),
                      accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      index.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      section.title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (section.body != null) ...[
            const SizedBox(height: 14),
            Text(
              section.body!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                height: 1.58,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...section.bullets.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.5,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String title;
  final String body;
  final String email;

  const _ContactCard({
    required this.title,
    required this.body,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.alternate_email_rounded,
                      size: 18, color: AppColors.brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      email,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
