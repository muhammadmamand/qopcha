import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/orders_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final ordersCount = ref.watch(ordersCountProvider);
    final favoritesCount = ref.watch(favoritesProvider).length;
    final cartCount = ref.watch(cartItemCountProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.brandWhite,
        body: Center(
          child: Text(
            'تکایە بچۆ ژوورەوە',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final location = user.location?.trim();
    final phone = user.phone.trim();
    final hasLocation = location != null && location.isNotEmpty;

    Future<void> logout() async {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.brandWhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text(
            'چوونەدەرەوە',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'دڵنیایت دەتەوێت لە هەژمارەکەت بچیتە دەرەوە؟',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'نەخێر',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text(
                'بەڵێ',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                ),
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
      backgroundColor: AppColors.brandWhite,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.brand.withValues(alpha: 0.12),
                      AppColors.brand.withValues(alpha: 0.03),
                      AppColors.brandWhite.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -40,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.highlight.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TopBar(
                          onSettings: () => context.push('/settings'),
                        )
                            .animate()
                            .fadeIn(duration: 380.ms)
                            .slideY(begin: 0.06),
                        const SizedBox(height: 22),
                        _IdentityHeader(
                          name: user.name,
                          email: user.email,
                          avatarUrl: user.avatarUrl,
                          onEdit: () {
                            HapticFeedback.selectionClick();
                            context.push('/settings/edit-profile');
                          },
                        )
                            .animate()
                            .fadeIn(delay: 40.ms, duration: 420.ms)
                            .slideY(begin: 0.08),
                        const SizedBox(height: 22),
                        _StatsRow(
                          favorites: favoritesCount,
                          orders: ordersCount,
                          cart: cartCount,
                          onFavorites: () => context.go('/favorites'),
                          onOrders: () => context.go('/orders'),
                          onCart: () => context.go('/cart'),
                        )
                            .animate()
                            .fadeIn(delay: 80.ms, duration: 420.ms)
                            .slideY(begin: 0.06),
                        const SizedBox(height: 28),
                        const _SectionLabel(title: 'زانیاری کەسی'),
                        const SizedBox(height: 12),
                        _InfoBlock(
                          phone: phone.isEmpty ? '—' : phone,
                          email: user.email,
                          location: hasLocation ? location : 'دیاری نەکراوە',
                          locationMissing: !hasLocation,
                          onEdit: () => context.push('/settings/edit-profile'),
                        )
                            .animate()
                            .fadeIn(delay: 120.ms, duration: 420.ms)
                            .slideY(begin: 0.05),
                        const SizedBox(height: 28),
                        const _SectionLabel(title: 'هەژمار'),
                        const SizedBox(height: 12),
                        _MenuBlock(
                          children: [
                            _MenuRow(
                              icon: Icons.person_outline_rounded,
                              label: 'دەستکاری پڕۆفایل',
                              hint: 'ناو، وێنە، مۆبایل، شوێن',
                              accent: AppColors.brand,
                              onTap: () =>
                                  context.push('/settings/edit-profile'),
                            ),
                            _MenuRow(
                              icon: Icons.receipt_long_outlined,
                              label: 'داواکارییەکانم',
                              hint: ordersCount > 0
                                  ? '$ordersCount داواکاری'
                                  : 'هیچ داواکارییەک نییە',
                              accent: AppColors.brand,
                              onTap: () => context.go('/orders'),
                            ),
                            _MenuRow(
                              icon: Icons.favorite_border_rounded,
                              label: 'دڵخوازەکان',
                              hint: favoritesCount > 0
                                  ? '$favoritesCount بەرهەم'
                                  : 'لیستەکەت بەتاڵە',
                              accent: AppColors.highlight,
                              onTap: () => context.go('/favorites'),
                            ),
                            _MenuRow(
                              icon: Icons.tune_rounded,
                              label: 'ڕێکخستنەکان',
                              hint: 'ڕووکار، ئاگاداری، سلایدەر',
                              accent: AppColors.textSecondary,
                              onTap: () => context.push('/settings'),
                              isLast: true,
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 160.ms, duration: 420.ms)
                            .slideY(begin: 0.05),
                        const SizedBox(height: 20),
                        _LogoutButton(onTap: logout)
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 420.ms),
                        const SizedBox(height: 120),
                      ],
                    ),
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

class _TopBar extends StatelessWidget {
  final VoidCallback onSettings;

  const _TopBar({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'پڕۆفایل',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Material(
          color: AppColors.brand.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onSettings,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.settings_outlined,
                color: AppColors.brand,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onEdit;

  const _IdentityHeader({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(name: name, avatarUrl: avatarUrl),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.highlight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: AppColors.highlight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'دەستکاری',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.highlight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _Avatar({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Container(
      width: 84,
      height: 84,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brand,
            AppColors.secondaryLight,
            AppColors.highlight.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandWhite,
        ),
        padding: const EdgeInsets.all(2.5),
        child: ClipOval(
          child: hasAvatar
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _AvatarFallback(name: name),
                  errorWidget: (_, _, _) => _AvatarFallback(name: name),
                )
              : _AvatarFallback(name: name),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;

  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppColors.brand,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int favorites;
  final int orders;
  final int cart;
  final VoidCallback onFavorites;
  final VoidCallback onOrders;
  final VoidCallback onCart;

  const _StatsRow({
    required this.favorites,
    required this.orders,
    required this.cart,
    required this.onFavorites,
    required this.onOrders,
    required this.onCart,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: '$favorites',
            label: 'دڵخواز',
            icon: Icons.favorite_rounded,
            color: AppColors.highlight,
            onTap: onFavorites,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '$orders',
            label: 'داواکاری',
            icon: Icons.receipt_long_rounded,
            color: AppColors.brand,
            onTap: onOrders,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '$cart',
            label: 'سەبەتە',
            icon: Icons.shopping_bag_rounded,
            color: AppColors.secondaryLight,
            onTap: onCart,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
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
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.14)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 15,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: AppColors.brand,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String phone;
  final String email;
  final String location;
  final bool locationMissing;
  final VoidCallback onEdit;

  const _InfoBlock({
    required this.phone,
    required this.email,
    required this.location,
    required this.locationMissing,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'مۆبایل',
            value: phone,
            ltr: true,
          ),
          _InfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'ئیمەیڵ',
            value: email,
            ltr: true,
          ),
          _InfoRow(
            icon: Icons.place_outlined,
            label: 'شوێن',
            value: location,
            valueColor: locationMissing ? AppColors.highlight : null,
            isLast: true,
            trailing: locationMissing
                ? GestureDetector(
                    onTap: onEdit,
                    child: Text(
                      'زیادکردن',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.highlight,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool ltr;
  final bool isLast;
  final Color? valueColor;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.ltr = false,
    this.isLast = false,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.65),
                ),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.brand.withValues(alpha: 0.75)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.5,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _MenuBlock extends StatelessWidget {
  final List<Widget> children;

  const _MenuBlock({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.brandWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final Color accent;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.accent,
    required this.onTap,
    this.isLast = false,
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
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 12, 10, isLast ? 12 : 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
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

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.22),
            ),
            color: AppColors.error.withValues(alpha: 0.06),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'چوونەدەرەوە',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
