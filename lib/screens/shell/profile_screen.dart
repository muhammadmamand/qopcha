import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_content_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/location_map_preview.dart';
import '../../widgets/premium_bottom_nav.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/telegram_theme_reveal.dart';

Future<void> _openSupportSheet(BuildContext context, WidgetRef ref) async {
  final content = ref.read(resolvedAppContentProvider);
  final phone = content.supportPhone.trim();
  final whatsapp = content.supportWhatsapp.trim();
  final email = content.supportEmail.trim();
  final hours = content.supportHours.trim();
  final instagram = AppContentModel.socialUrl(
    content.socialInstagram,
    platform: 'instagram',
  );
  final facebook = AppContentModel.socialUrl(
    content.socialFacebook,
    platform: 'facebook',
  );
  final tiktok = AppContentModel.socialUrl(
    content.socialTikTok,
    platform: 'tiktok',
  );
  final telegram = AppContentModel.socialUrl(
    content.socialTelegram,
    platform: 'telegram',
  );
  final hasContact =
      phone.isNotEmpty || whatsapp.isNotEmpty || email.isNotEmpty;
  final hasSocial =
      instagram != null ||
      facebook != null ||
      tiktok != null ||
      telegram != null;

  Future<void> openUri(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'نەتوانرا بکرێتەوە',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
      );
    }
  }

  Widget socialTile({
    required IconData icon,
    required String title,
    required String url,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.brand),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        url,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.open_in_new_rounded,
        size: 18,
        color: AppColors.textTertiary,
      ),
      onTap: () => openUri(Uri.parse(url)),
    );
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.78,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'یارمەتی و پشتگیری',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (hours.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'کاتی کارکردن: $hours',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (phone.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.call_rounded, color: AppColors.brand),
                    title: Text(
                      phone,
                      textDirection: ui.TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      'پەیوەندی تەلەفۆن',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () => openUri(Uri(scheme: 'tel', path: phone)),
                  ),
                if (whatsapp.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.chat_rounded, color: AppColors.brand),
                    title: Text(
                      whatsapp,
                      textDirection: ui.TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      'واتساپ',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () {
                      final digits = whatsapp.replaceAll(RegExp(r'[^\d+]'), '');
                      openUri(Uri.parse('https://wa.me/$digits'));
                    },
                  ),
                if (email.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.email_outlined, color: AppColors.brand),
                    title: Text(
                      email,
                      textDirection: ui.TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      'ئیمەیڵ',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () => openUri(Uri(scheme: 'mailto', path: email)),
                  ),
                if (hasSocial) ...[
                  const SizedBox(height: 8),
                  Text(
                    'سۆشیال میدیا',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (instagram != null)
                    socialTile(
                      icon: Icons.camera_alt_outlined,
                      title: 'Instagram',
                      url: instagram,
                    ),
                  if (facebook != null)
                    socialTile(
                      icon: Icons.facebook_rounded,
                      title: 'Facebook',
                      url: facebook,
                    ),
                  if (tiktok != null)
                    socialTile(
                      icon: Icons.music_note_rounded,
                      title: 'TikTok',
                      url: tiktok,
                    ),
                  if (telegram != null)
                    socialTile(
                      icon: Icons.send_rounded,
                      title: 'Telegram',
                      url: telegram,
                    ),
                ],
                if (!hasContact && !hasSocial)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'هێشتا زانیاری پشتگیری دانەنراوە',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appSettingsProvider.select((s) => s.themeMode));
    final user = ref.watch(currentUserProvider);
    final favoritesCount = ref.watch(favoritesProvider).length;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 42,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'میوانیت',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'دەتوانیت بەرهەمەکان ببینیت. بۆ داواکردن و پرۆفایل، بچۆ ژوورەوە.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => context.push('/auth?next=/profile'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'چوونەژوورەوە',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      context.push('/auth?tab=signup&next=/profile'),
                  child: Text(
                    'دروستکردنی هەژمار',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final unseen = ref.watch(unseenOrderTabCountsProvider);
    final pending = unseen['pending'] ?? 0;
    final confirmed = (unseen['confirmed'] ?? 0) + (unseen['ready'] ?? 0);
    final shipped = unseen['shipped'] ?? 0;
    final delivered = unseen['delivered'] ?? 0;
    final returned = unseen['returned'] ?? 0;

    Future<void> logout() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.sheet,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'چوونەدەرەوە',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'دڵنیایت دەتەوێت بچیتە دەرەوە؟',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('نەخێر'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('بەڵێ'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/home');
    }

    void soon() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'بەمزووانە بەردەست دەبێت',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDarkMode = switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };

    Future<void> toggleTheme(BuildContext buttonContext) async {
      HapticFeedback.selectionClick();
      final next = isDarkMode ? ThemeMode.light : ThemeMode.dark;
      final reveal = TelegramThemeReveal.of(context);
      if (reveal == null) {
        await ref.read(appSettingsProvider.notifier).setThemeMode(next);
        return;
      }
      await reveal.reveal(
        center: TelegramThemeReveal.centerFrom(buttonContext),
        reverse: isDarkMode,
        onThemeChange: () {
          ref.read(appSettingsProvider.notifier).setThemeMode(next);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            kPremiumBottomNavClearance + 24,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
              Row(
                children: [
                  Text(
                    'پڕۆفایلی من',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (btnCtx) => _HeaderIcon(
                      icon: isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      onTap: () => toggleTheme(btnCtx),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderIcon(
                    icon: Icons.settings_outlined,
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 20),
              _ProfileHeader(
                    user: user,
                    onEdit: () {
                      HapticFeedback.selectionClick();
                      context.push('/settings/edit-profile');
                    },
                  )
                  .animate()
                  .fadeIn(delay: 40.ms, duration: 400.ms)
                  .slideY(begin: 0.04, curve: Curves.easeOutCubic),
              if (user.hasMapPin) ...[
                const SizedBox(height: 14),
                LocationMapPreview(
                      latitude: user.latitude!,
                      longitude: user.longitude!,
                      caption: user.location?.trim().isNotEmpty == true
                          ? user.location
                          : 'شوێنی گەیاندن',
                    )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 400.ms)
                    .slideY(begin: 0.04, curve: Curves.easeOutCubic),
              ] else if ((user.location ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _LocationTextCard(
                  location: user.location!.trim(),
                  onEdit: () => context.push('/settings/edit-profile'),
                ),
              ],
              const SizedBox(height: 16),
              _OrdersCard(
                    pending: pending,
                    confirmed: confirmed,
                    shipped: shipped,
                    delivered: delivered,
                    returned: returned,
                    onViewAll: () => context.go('/orders'),
                    onOpenTab: (tab) => context.go('/orders?tab=$tab'),
                  )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 400.ms)
                  .slideY(begin: 0.04, curve: Curves.easeOutCubic),
              const SizedBox(height: 14),
              _MenuCard(
                    items: [
                      _MenuEntry(
                        icon: Icons.person_outline_rounded,
                        title: 'زانیاری کەسی',
                        onTap: () => context.push('/settings/edit-profile'),
                      ),
                      _MenuEntry(
                        icon: Icons.location_on_outlined,
                        title: 'ناونیشانەکان',
                        onTap: () => context.push('/settings/addresses'),
                      ),
                      if (user.isCustomer)
                        _MenuEntry(
                          icon: Icons.straighten_rounded,
                          title: 'قیاسی جەستەم',
                          onTap: () => context.push('/settings/measurements'),
                        ),
                      _MenuEntry(
                        icon: Icons.credit_card_outlined,
                        title: 'شێوازەکانی پارەدان',
                        onTap: () => context.push('/settings/payment-methods'),
                      ),
                      _MenuEntry(
                        icon: favoritesCount > 0
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        title: 'دڵخوازەکانم',
                        onTap: () => context.push('/favorites'),
                        badge: favoritesCount,
                        pulseHeart: favoritesCount > 0,
                      ),
                      _MenuEntry(
                        icon: Icons.star_border_rounded,
                        title: 'هەڵسەنگاندنەکانم',
                        onTap: soon,
                      ),
                      _MenuEntry(
                        icon: Icons.local_offer_outlined,
                        title: 'داشکاندنەکان',
                        onTap: () => context.go('/discounts'),
                      ),
                      _MenuEntry(
                        icon: Icons.headset_mic_outlined,
                        title: 'یارمەتی و پشتگیری',
                        onTap: () => _openSupportSheet(context, ref),
                      ),
                      _MenuEntry(
                        icon: Icons.logout_rounded,
                        title: 'چوونەدەرەوە',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          logout();
                        },
                        isLogout: true,
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 400.ms)
                  .slideY(begin: 0.04, curve: Curves.easeOutCubic),
            ],
          ),
        ),
      );
    }
}

class _LocationTextCard extends StatelessWidget {
  final String location;
  final VoidCallback onEdit;

  const _LocationTextCard({required this.location, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.highlight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.highlight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شوێنی گەیاندن',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.my_location_rounded,
                color: AppColors.brand.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: AppColors.textPrimary),
              if (badge)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.highlight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.card, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.user,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final phone = user.phone.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileAvatar(
          name: user.name,
          avatarValue: user.avatarUrl,
          size: 72,
          showBorder: true,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (user.isApproved) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: AppColors.brand,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: ui.TextDirection.ltr,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  phone,
                  textDirection: ui.TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (user.isCustomer &&
                  (user.preferredSize ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'قەبارە: ${user.preferredSize}',
                    textDirection: ui.TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onEdit,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 14, color: AppColors.brand),
                    const SizedBox(width: 4),
                    Text(
                      'دەستکاری پڕۆفایل',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrdersCard extends StatelessWidget {
  final int pending;
  final int confirmed;
  final int shipped;
  final int delivered;
  final int returned;
  final VoidCallback onViewAll;
  final ValueChanged<String> onOpenTab;

  const _OrdersCard({
    required this.pending,
    required this.confirmed,
    required this.shipped,
    required this.delivered,
    required this.returned,
    required this.onViewAll,
    required this.onOpenTab,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.inventory_2_outlined, null, 'چاوەڕوان', pending, 'pending'),
      (Icons.verified_outlined, null, 'قبوڵکراو', confirmed, 'confirmed'),
      (null, 'assets/images/car.png', 'نێردراو', shipped, 'shipped'),
      (
        Icons.check_circle_outline_rounded,
        null,
        'گەیشتوو',
        delivered,
        'delivered',
      ),
      (Icons.replay_rounded, null, 'گەڕاوە', returned, 'returned'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'داواکارییەکانم',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: Row(
                  children: [
                    Text(
                      'بینینی هەموو',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 18,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _OrderStatusItem(
                    icon: item.$1,
                    imageAsset: item.$2,
                    label: item.$3,
                    badge: item.$4,
                    onTap: () => onOpenTab(item.$5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderStatusItem extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _OrderStatusItem({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.badge,
    required this.onTap,
  });

  Widget _buildIcon() {
    if (imageAsset != null) {
      final color = AppColors.isDark ? Colors.white : AppColors.textSecondary;
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: Image.asset(
          imageAsset!,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        ),
      );
    }
    return Icon(icon, size: 26, color: AppColors.textSecondary);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: imageAsset != null ? 56 : 42,
            height: imageAsset != null ? 56 : 42,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _buildIcon(),
                if (badge > 0)
                  Positioned(
                    top: -2,
                    right: 0,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.highlight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int badge;
  final bool pulseHeart;
  final bool isLogout;

  const _MenuEntry({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge = 0,
    this.pulseHeart = false,
    this.isLogout = false,
  });
}

class _MenuCard extends StatelessWidget {
  final List<_MenuEntry> items;

  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _MenuTile(entry: items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 56,
                endIndent: 16,
                color: AppColors.border.withValues(alpha: 0.55),
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuEntry entry;

  const _MenuTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isLogout = entry.isLogout;
    final hasFavorites = entry.pulseHeart && entry.badge > 0;
    final color = isLogout ? AppColors.error : AppColors.textPrimary;
    final iconColor = isLogout
        ? AppColors.error
        : hasFavorites
        ? AppColors.highlight
        : AppColors.textSecondary;

    Widget icon = Icon(entry.icon, size: 22, color: iconColor);
    if (hasFavorites) {
      icon = _PulsingFavoriteIcon(icon: entry.icon, color: iconColor);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          entry.onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: hasFavorites
                ? AppColors.highlight.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  entry.title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (entry.badge > 0) ...[
                Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.ctaGradient,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.highlight.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        entry.badge > 99 ? '99+' : '${entry.badge}',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.06, 1.06),
                      duration: 900.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: hasFavorites
                    ? AppColors.highlight.withValues(alpha: 0.7)
                    : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft heartbeat so the user notices they already have favorites.
class _PulsingFavoriteIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _PulsingFavoriteIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.highlight.withValues(alpha: 0.14),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.25, 1.25),
                duration: 900.ms,
                curve: Curves.easeInOut,
              )
              .fade(begin: 0.55, end: 0.0, duration: 900.ms),
          Icon(icon, size: 22, color: color)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.18, 1.18),
                duration: 700.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }
}
