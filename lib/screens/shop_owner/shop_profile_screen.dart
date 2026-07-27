import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/product_provider.dart';

class ShopProfileScreen extends ConsumerWidget {
  const ShopProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('تکایە بچۆ ژوورەوە')));
    }

    final productsAsync = ref.watch(shopProductsProvider(user.id));
    final ordersAsync = ref.watch(shopOrdersProvider);
    final pendingCount = ref.watch(shopPendingOrdersCountProvider);
    final productCount = productsAsync.valueOrNull?.length ?? 0;
    final orderCount = ordersAsync.valueOrNull?.length ?? 0;

    Future<void> logout() async {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('چوونەدەرەوە'),
          content: const Text('دڵنیایت دەتەوێت لە هەژمارەکەت بچیتە دەرەوە؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('نەخێر'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'بەڵێ',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      if (shouldLogout != true) return;
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/auth');
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          _ShopHeader(
            user: user,
            onEditTap: () => context.push('/settings/edit-profile'),
          ),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _ShopInfoCard(user: user),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _BusinessStat(
                          icon: Icons.inventory_2_rounded,
                          label: 'بەرهەم',
                          value: '$productCount',
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BusinessStat(
                          icon: Icons.receipt_long_rounded,
                          label: 'داواکاری',
                          value: '$orderCount',
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BusinessStat(
                          icon: Icons.pending_actions_rounded,
                          label: 'چاوەڕوان',
                          value: '$pendingCount',
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'بەڕێوەبردنی دووکان',
                    children: [
                      _ShopMenuTile(
                        icon: Icons.dashboard_rounded,
                        label: 'داشبۆرد',
                        subtitle: 'بینینی بەرهەم و ئامارەکان',
                        color: AppColors.secondary,
                        onTap: () => context.go('/shop'),
                      ),
                      _ShopMenuTile(
                        icon: Icons.receipt_long_rounded,
                        label: 'داواکارییەکان',
                        subtitle: 'قبوڵکردن و بەڕێوەبردنی داواکاری',
                        color: AppColors.warning,
                        badge: pendingCount > 0 ? pendingCount : null,
                        onTap: () => context.go('/shop-orders'),
                      ),
                      _ShopMenuTile(
                        icon: Icons.add_box_outlined,
                        label: 'بەرهەمی نوێ',
                        subtitle: 'زیادکردنی بەرهەم بۆ دووکان',
                        color: const Color(0xFF7C3AED),
                        onTap: () => context.push('/shop/add-product'),
                      ),
                      _ShopMenuTile(
                        icon: Icons.storefront_outlined,
                        label: 'زانیاری دووکان',
                        subtitle: 'ناو، ناونیشان، وەسف',
                        color: AppColors.success,
                        onTap: () => context.push('/settings/edit-profile'),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'هەژمار',
                    children: [
                      _ShopMenuTile(
                        icon: Icons.person_outline_rounded,
                        label: 'دەستکاری پڕۆفایل',
                        subtitle: 'ناو، ئیمەیڵ، تەلەفۆن',
                        color: AppColors.textSecondary,
                        onTap: () => context.push('/settings/edit-profile'),
                      ),
                      _ShopMenuTile(
                        icon: Icons.settings_outlined,
                        label: 'ڕێکخستنەکان',
                        subtitle: 'ڕووکار، زمان، ئاگاداری',
                        color: AppColors.textSecondary,
                        onTap: () => context.push('/settings'),
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ShopLogoutButton(onTap: logout),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEditTap;

  const _ShopHeader({required this.user, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final shopName = user.shopName?.trim().isNotEmpty == true
        ? user.shopName!
        : 'دووکانەکەم';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16,
        24,
        56,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'پڕۆفایلی دووکان',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onEditTap,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: user.avatarUrl != null &&
                          user.avatarUrl!.trim().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _ShopAvatarFallback(
                            name: shopName,
                          ),
                        )
                      : _ShopAvatarFallback(name: shopName),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            shopName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.name,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          _TierBadge(tier: user.effectiveShopTier),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _TierBadge extends StatelessWidget {
  final ShopTier tier;

  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final (Color accent, IconData icon) = switch (tier) {
      ShopTier.silver => (const Color(0xFFD1D5DB), Icons.workspace_premium_outlined),
      ShopTier.gold => (AppColors.gold, Icons.workspace_premium_rounded),
      ShopTier.platinum => (const Color(0xFF93C5FD), Icons.diamond_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            '${tier.labelKu} · ${tier.labelEn}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopAvatarFallback extends StatelessWidget {
  final String name;

  const _ShopAvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF1FF),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? 'د' : name[0],
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ShopInfoCard extends StatelessWidget {
  final UserModel user;

  const _ShopInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final description = user.shopDescription?.trim();
    final address = user.shopAddress?.trim();
    final phone = user.phone.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'زانیاری دووکان',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (address != null && address.isNotEmpty)
            _InfoRow(icon: Icons.location_on_outlined, text: address),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone_outlined, text: phone),
          ],
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.mail_outline_rounded,
            text: user.email,
            ltr: true,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.06);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool ltr;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.ltr = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: ltr ? TextDirection.ltr : null,
            textAlign: ltr ? TextAlign.right : TextAlign.start,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BusinessStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BusinessStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: AppDecorations.card(radius: 18),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: AppDecorations.card(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _ShopMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final int? badge;
  final bool isLast;
  final VoidCallback onTap;

  const _ShopMenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null && badge! > 0)
                  Container(
                    margin: const EdgeInsetsDirectional.only(end: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopLogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ShopLogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.error.withValues(alpha: 0.12),
                AppColors.error.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'چوونەدەرەوە',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        'دەرچوون لە هەژماری دووکان',
                        style: TextStyle(
                          color: Color(0xFFB85A63),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.error.withValues(alpha: 0.7),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
