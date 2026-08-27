import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/banner_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_storage_service.dart';
import '../../services/maps_launcher_service.dart';

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _indexFor(String location) {
    if (location.startsWith('/admin/leaders')) return 1;
    if (location.startsWith('/admin/orders')) return 2;
    if (location.startsWith('/admin/delivery')) return 3;
    if (location.startsWith('/admin/reports')) return 4;
    if (location.startsWith('/admin/products')) return 5;
    if (location.startsWith('/admin/discounts')) return 6;
    if (location.startsWith('/admin/banners')) return 7;
    if (location.startsWith('/admin/content')) return 8;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);
    final pendingAccounts =
        ref.watch(pendingUsersProvider).valueOrNull?.length ?? 0;
    final pendingOrders = ref.watch(adminPendingOrdersCountProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    ref.listen<int>(adminPendingOrdersCountProvider, (previous, next) {
      if (previous == null) return;
      if (next <= previous || !mounted) return;
      final added = next - previous;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  added == 1
                      ? 'داواکارییەکی نوێ هات'
                      : '$added داواکاریی نوێ هات',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.highlight,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'بینین',
            textColor: Colors.white,
            onPressed: () => context.go('/admin/orders'),
          ),
        ),
      );
    });

    void goTab(int i) {
      HapticFeedback.selectionClick();
      switch (i) {
        case 0:
          context.go('/admin');
        case 1:
          context.go('/admin/leaders');
        case 2:
          context.go('/admin/orders');
        case 3:
          context.go('/admin/delivery');
        case 4:
          context.go('/admin/reports');
        case 5:
          context.go('/admin/products');
        case 6:
          context.go('/admin/discounts');
        case 7:
          context.go('/admin/banners');
        case 8:
          context.go('/admin/content');
      }
    }

    final wide = MediaQuery.sizeOf(context).width >= 980;
    final destinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: Badge(
          isLabelVisible: pendingAccounts > 0,
          label: Text('$pendingAccounts'),
          child: const Icon(Icons.people_outline_rounded),
        ),
        selectedIcon: Badge(
          isLabelVisible: pendingAccounts > 0,
          label: Text('$pendingAccounts'),
          child: const Icon(Icons.people_rounded),
        ),
        label: const Text('هەژمار'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.emoji_events_outlined),
        selectedIcon: Icon(Icons.emoji_events_rounded),
        label: Text('باشترین'),
      ),
      NavigationRailDestination(
        icon: Badge(
          isLabelVisible: pendingOrders > 0,
          label: Text('$pendingOrders'),
          child: const Icon(Icons.inbox_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: pendingOrders > 0,
          label: Text('$pendingOrders'),
          child: const Icon(Icons.inbox_rounded),
        ),
        label: const Text('وەرگرتن'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.local_shipping_outlined),
        selectedIcon: Icon(Icons.local_shipping_rounded),
        label: Text('گەیاندن'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics_rounded),
        label: Text('ڕاپۆرت'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2_rounded),
        label: Text('کاڵا'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.percent_outlined),
        selectedIcon: Icon(Icons.percent_rounded),
        label: Text('داشکاندن'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.view_carousel_outlined),
        selectedIcon: Icon(Icons.view_carousel_rounded),
        label: Text('ڕیکلام'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.article_outlined),
        selectedIcon: Icon(Icons.article_rounded),
        label: Text('ناوەڕۆک'),
      ),
    ];

    if (wide) {
      return Scaffold(
        backgroundColor: AppColors.surfaceVariant,
        body: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.9),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(-4, 0),
                  ),
                ],
              ),
              child: NavigationRail(
                extended: MediaQuery.sizeOf(context).width >= 1180,
                backgroundColor: Colors.white,
                selectedIndex: index.clamp(0, destinations.length - 1),
                onDestinationSelected: goTab,
                labelType: MediaQuery.sizeOf(context).width >= 1180
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                indicatorColor: AppColors.brand.withValues(alpha: 0.12),
                selectedIconTheme: IconThemeData(color: AppColors.brand),
                unselectedIconTheme: IconThemeData(
                  color: AppColors.textTertiary,
                ),
                selectedLabelTextStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand,
                ),
                unselectedLabelTextStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  child: MediaQuery.sizeOf(context).width >= 1180
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'قۆپچە',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: AppColors.brand,
                                  ),
                                ),
                                Text(
                                  'پانێڵی ئەدمین',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                ),
                destinations: destinations,
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.surfaceVariant,
                child: widget.child,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 10 + bottom),
        child: _AdminBottomBar(
          index: index,
          pendingAccounts: pendingAccounts,
          pendingOrders: pendingOrders,
          onTap: goTab,
        ),
      ),
    );
  }
}

class _AdminBottomBar extends StatelessWidget {
  final int index;
  final int pendingAccounts;
  final int pendingOrders;
  final ValueChanged<int> onTap;

  const _AdminBottomBar({
    required this.index,
    required this.pendingAccounts,
    required this.pendingOrders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.people_outline_rounded,
        Icons.people_rounded,
        'هەژمار',
        pendingAccounts,
      ),
      (
        Icons.emoji_events_outlined,
        Icons.emoji_events_rounded,
        'باشترین',
        0,
      ),
      (
        Icons.inbox_outlined,
        Icons.inbox_rounded,
        'وەرگرتن',
        pendingOrders,
      ),
      (
        Icons.local_shipping_outlined,
        Icons.local_shipping_rounded,
        'گەیاندن',
        0,
      ),
      (
        Icons.analytics_outlined,
        Icons.analytics_rounded,
        'ڕاپۆرت',
        0,
      ),
      (
        Icons.inventory_2_outlined,
        Icons.inventory_2_rounded,
        'کاڵا',
        0,
      ),
      (
        Icons.percent_outlined,
        Icons.percent_rounded,
        'داشکاندن',
        0,
      ),
      (
        Icons.view_carousel_outlined,
        Icons.view_carousel_rounded,
        'ڕیکلام',
        0,
      ),
      (
        Icons.article_outlined,
        Icons.article_rounded,
        'ناوەڕۆک',
        0,
      ),
    ];

    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) => SizedBox(
          width: 72,
          child: _AdminNavItem(
            icon: items[i].$1,
            activeIcon: items[i].$2,
            label: items[i].$3,
            badge: items[i].$4,
            selected: index == i,
            onTap: () => onTap(i),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.brand;
    final idle = AppColors.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brand.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: badge > 0,
                backgroundColor: AppColors.highlight,
                label: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                child: AnimatedScale(
                  scale: selected ? 1.06 : 1,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    selected ? activeIcon : icon,
                    size: 21,
                    color: selected ? accent : idle,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  color: selected ? accent : idle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AccountRoleFilter { customers, shops }

enum _AccountStatusFilter { pending, approved, rejected }

class AdminAccountsScreen extends ConsumerStatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  ConsumerState<AdminAccountsScreen> createState() =>
      _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends ConsumerState<AdminAccountsScreen> {
  _AccountRoleFilter _roleFilter = _AccountRoleFilter.customers;
  _AccountStatusFilter _statusFilter = _AccountStatusFilter.pending;

  Future<void> _setStatus(
    UserModel user,
    ApprovalStatus status, {
    String? rejectionReason,
  }) async {
    try {
      await ref.read(adminServiceProvider).setApproval(
            user.id,
            status,
            rejectionReason: rejectionReason,
          );
      if (!mounted) return;
      final msg = status == ApprovalStatus.approved
          ? 'هەژماری ${user.name} پەسەند کرا'
          : 'هەژماری ${user.name} ڕەتکرایەوە';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(msg, style: const TextStyle(fontFamily: AppTheme.fontFamily)),
          backgroundColor: status == ApprovalStatus.approved
              ? AppColors.brand
              : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'نەتوانرا نوێ بکرێتەوە — ڕێساکانی Firestore بپشکنە',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _rejectWithReason(UserModel user) async {
    final controller = TextEditingController(
      text: user.rejectionReason ?? '',
    );
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ڕەتکردنەوەی ${user.name}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'هۆکار بنووسە تا بەکارهێنەر بزانێت بۆچی هەژمارەکەی پەسەند نەکرا',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'نموونە: زانیاری هەژمار ناتەواوە...',
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx, text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('ڕەتکردنەوە'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('پاشگەزبوونەوە'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (reason == null || reason.isEmpty || !mounted) return;
    await _setStatus(
      user,
      ApprovalStatus.rejected,
      rejectionReason: reason,
    );
  }

  List<UserModel> _byRole(List<UserModel> all) {
    return switch (_roleFilter) {
      _AccountRoleFilter.customers =>
        all.where((u) => u.isCustomer).toList(),
      _AccountRoleFilter.shops => all.where((u) => u.isShopOwner).toList(),
    };
  }

  List<UserModel> _byStatus(List<UserModel> roleList) {
    return switch (_statusFilter) {
      _AccountStatusFilter.pending => roleList
          .where((u) => u.approvalStatus == ApprovalStatus.pending)
          .toList(),
      _AccountStatusFilter.approved => roleList
          .where((u) => u.approvalStatus == ApprovalStatus.approved)
          .toList(),
      _AccountStatusFilter.rejected => roleList
          .where((u) => u.approvalStatus == ApprovalStatus.rejected)
          .toList(),
    };
  }

  String get _emptyMessage {
    final role = _roleFilter == _AccountRoleFilter.customers
        ? 'کڕیار'
        : 'دووکان';
    return switch (_statusFilter) {
      _AccountStatusFilter.pending => 'هیچ هەژماری $roleی چاوەڕوان نییە',
      _AccountStatusFilter.approved => 'هیچ هەژماری $roleی پەسەندکراو نییە',
      _AccountStatusFilter.rejected => 'هیچ هەژماری $roleی ڕەتکراوە نییە',
    };
  }

  String get _sectionTitle {
    final role = _roleFilter == _AccountRoleFilter.customers
        ? 'کڕیارەکان'
        : 'دووکانەکان';
    final status = switch (_statusFilter) {
      _AccountStatusFilter.pending => 'چاوەڕوان',
      _AccountStatusFilter.approved => 'پەسەندکراو',
      _AccountStatusFilter.rejected => 'ڕەتکراوە',
    };
    return '$role · $status';
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allManagedUsersProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeader(
            title: 'هەژمارەکان',
            subtitle: 'کڕیار و دووکان — بە جیا ڕێکخراو',
            onLogout: () => ref.read(authProvider.notifier).logout(),
            showNotifications: true,
          ),
          Expanded(
            child: allAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'هەڵە لە خوێندنەوەی هەژمارەکان:\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: AppTheme.fontFamily),
                  ),
                ),
              ),
              data: (all) {
                final customers = all.where((u) => u.isCustomer).toList();
                final shops = all.where((u) => u.isShopOwner).toList();
                final roleList = _byRole(all);
                final filtered = _byStatus(roleList);

                final pendingCount = roleList
                    .where((u) => u.approvalStatus == ApprovalStatus.pending)
                    .length;
                final approvedCount = roleList
                    .where((u) => u.approvalStatus == ApprovalStatus.approved)
                    .length;
                final rejectedCount = roleList
                    .where((u) => u.approvalStatus == ApprovalStatus.rejected)
                    .length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _AccountStatCard(
                            label: 'کڕیار',
                            value: '${customers.length}',
                            icon: Icons.person_outline_rounded,
                            color: AppColors.brand,
                            selected:
                                _roleFilter == _AccountRoleFilter.customers,
                            onTap: () => setState(
                              () =>
                                  _roleFilter = _AccountRoleFilter.customers,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AccountStatCard(
                            label: 'دووکان',
                            value: '${shops.length}',
                            icon: Icons.storefront_outlined,
                            color: AppColors.highlight,
                            selected: _roleFilter == _AccountRoleFilter.shops,
                            onTap: () => setState(
                              () => _roleFilter = _AccountRoleFilter.shops,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _roleFilter == _AccountRoleFilter.customers
                          ? 'هەژماری کڕیارەکان'
                          : 'هەژماری دووکانەکان',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatusFilterChip(
                            label: 'چاوەڕوان',
                            count: pendingCount,
                            color: AppColors.highlight,
                            selected: _statusFilter ==
                                _AccountStatusFilter.pending,
                            onTap: () => setState(
                              () => _statusFilter =
                                  _AccountStatusFilter.pending,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatusFilterChip(
                            label: 'پەسەندکراو',
                            count: approvedCount,
                            color: AppColors.success,
                            selected: _statusFilter ==
                                _AccountStatusFilter.approved,
                            onTap: () => setState(
                              () => _statusFilter =
                                  _AccountStatusFilter.approved,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatusFilterChip(
                            label: 'ڕەتکراوە',
                            count: rejectedCount,
                            color: AppColors.error,
                            selected: _statusFilter ==
                                _AccountStatusFilter.rejected,
                            onTap: () => setState(
                              () => _statusFilter =
                                  _AccountStatusFilter.rejected,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _sectionTitle,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          '${filtered.length}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (filtered.isEmpty)
                      _EmptyHint(text: _emptyMessage)
                    else
                      ...filtered.map(
                        (u) => _UserCard(
                          user: u,
                          highlight: u.approvalStatus == ApprovalStatus.pending,
                          onApprove:
                              u.approvalStatus != ApprovalStatus.approved
                                  ? () => _setStatus(
                                        u,
                                        ApprovalStatus.approved,
                                      )
                                  : null,
                          onReject:
                              u.approvalStatus != ApprovalStatus.rejected
                                  ? () => _rejectWithReason(u)
                                  : null,
                          onTierChanged: u.isShopOwner
                              ? (tier) async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  try {
                                    await ref
                                        .read(adminServiceProvider)
                                        .setShopTier(u.id, tier);
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'پلانی دووکان بوو بە ${tier.labelKu}',
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                          ),
                                        ),
                                        backgroundColor: AppColors.brand,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (_) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'نەتوانرا پلان بگۆڕدرێت',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                          ),
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AccountStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : AppColors.surfaceVariant.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.55)
                  : AppColors.border.withValues(alpha: 0.8),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: selected ? color : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.14)
                : AppColors.surfaceVariant.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.5)
                  : AppColors.border.withValues(alpha: 0.75),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: selected ? color : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: selected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminBannersScreen extends ConsumerWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(adminBannersProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminHeader(
            title: 'ڕیکلامی سلایدەر',
            subtitle:
                'قەبارەی وێنە: ${BannerModel.recommendedWidthPx}×${BannerModel.recommendedHeightPx}px',
            showNotifications: true,
            action: IconButton(
              onPressed: () => _openBannerEditor(context, ref, null),
              tooltip: 'ڕیکلامی نوێ',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.brand.withValues(alpha: 0.10),
              ),
              icon: Icon(Icons.add_rounded, color: AppColors.brand),
            ),
          ),
          Expanded(
            child: bannersAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
              error: (e, _) => Center(child: Text('$e')),
              data: (banners) {
                if (banners.isEmpty) {
                  return _BannersEmpty(
                    onCreate: () => _openBannerEditor(context, ref, null),
                  );
                }

                final active =
                    banners.where((b) => b.active).length;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: _BannerSizeGuide(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Row(
                          children: [
                            _BannerStatChip(
                              label: 'هەموو',
                              value: '${banners.length}',
                              color: AppColors.brand,
                            ),
                            const SizedBox(width: 10),
                            _BannerStatChip(
                              label: 'چالاک',
                              value: '$active',
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            _BannerStatChip(
                              label: 'ناچالاک',
                              value: '${banners.length - active}',
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      sliver: SliverList.separated(
                        itemCount: banners.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (_, i) {
                          final b = banners[i];
                          return _BannerTile(
                            banner: b,
                            onEdit: () =>
                                _openBannerEditor(context, ref, b),
                            onToggle: (v) => ref
                                .read(adminServiceProvider)
                                .setBannerActive(b.id, v),
                            onDelete: () => _confirmDelete(
                              context,
                              ref,
                              b,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BannerModel banner,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'سڕینەوەی ڕیکلام',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'دڵنیایت دەتەوێت ئەم ڕیکلامە بسڕیتەوە؟',
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
            child: const Text('سڕینەوە'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(adminServiceProvider).deleteBanner(banner.id);
  }

  Future<void> _openBannerEditor(
    BuildContext context,
    WidgetRef ref,
    BannerModel? existing,
  ) async {
    final saved = await showModalBottomSheet<BannerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _BannerEditorSheet(existing: existing),
    );

    if (saved == null) return;
    await ref.read(adminServiceProvider).saveBanner(saved);
  }
}

class _BannersEmpty extends StatelessWidget {
  final VoidCallback onCreate;

  const _BannersEmpty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.07),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brand.withValues(alpha: 0.14),
                      AppColors.highlight.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.view_carousel_rounded,
                  size: 34,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'هیچ ڕیکلامێک نییە',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'وێنەیەک بە قەبارەی ${BannerModel.recommendedWidthPx}×${BannerModel.recommendedHeightPx} زیاد بکە بۆ سلایدەری هۆم',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'زیادکردنی ڕیکلام',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
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

class _BannerStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BannerStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerEditorSheet extends StatefulWidget {
  final BannerModel? existing;

  const _BannerEditorSheet({this.existing});

  @override
  State<_BannerEditorSheet> createState() => _BannerEditorSheetState();
}

class _BannerEditorSheetState extends State<_BannerEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _highlight;
  late final TextEditingController _subtitle;
  late final TextEditingController _cta;
  late final TextEditingController _tag;
  late final TextEditingController _imageUrl;
  late final TextEditingController _order;
  final _picker = ImagePicker();
  final _storage = ImageStorageService();
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _highlight = TextEditingController(text: e?.highlight ?? '');
    _subtitle = TextEditingController(text: e?.subtitle ?? '');
    _cta = TextEditingController(text: e?.cta ?? 'بینین');
    _tag = TextEditingController(text: e?.tag ?? 'AD');
    _imageUrl = TextEditingController(text: e?.imageUrl ?? '');
    _order = TextEditingController(text: (e?.order ?? 0).toString());
  }

  @override
  void dispose() {
    _title.dispose();
    _highlight.dispose();
    _subtitle.dispose();
    _cta.dispose();
    _tag.dispose();
    _imageUrl.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_uploading) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: BannerModel.recommendedWidthPx.toDouble(),
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final url = await _storage.persistXFilePathOrBytes(
        path: file.path,
        bytes: bytes,
        folder: 'banner_images',
      );
      if (!mounted) return;
      setState(() => _imageUrl.text = url);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'نەتوانرا وێنە باربکرێت. مۆڵەت و ئینتەرنێت بپشکنە.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _save() {
    final url = _imageUrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'تکایە وێنەیەک باربکە یان لینک بنووسە');
      return;
    }
    Navigator.pop(
      context,
      BannerModel(
        id: widget.existing?.id ?? '',
        title: _title.text.trim(),
        highlight: _highlight.text.trim(),
        subtitle: _subtitle.text.trim(),
        cta: _cta.text.trim().isEmpty ? 'بینین' : _cta.text.trim(),
        tag: _tag.text.trim().isEmpty ? 'AD' : _tag.text.trim(),
        imageUrl: url,
        active: widget.existing?.active ?? true,
        order: int.tryParse(_order.text.trim()) ?? 0,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _imageUrl.text.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'ڕیکلامی نوێ' : 'دەستکاری ڕیکلام',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const _BannerSizeGuide(),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: BannerModel.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: AppColors.surfaceVariant,
                  child: preview.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.aspect_ratio_rounded,
                                color: AppColors.brand.withValues(alpha: 0.7),
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'وێنەی ڕیکلام',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${BannerModel.recommendedWidthPx} × ${BannerModel.recommendedHeightPx}',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brand,
                                ),
                              ),
                            ],
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: preview,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: (_, _, _) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading
                        ? null
                        : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('گەلەری'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _uploading ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('کامێرا'),
                  ),
                ),
              ],
            ),
            if (_uploading) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(color: AppColors.brand),
              const SizedBox(height: 6),
              Text(
                'بارکردنی وێنە…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppColors.error,
                  fontSize: 12.5,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrl,
              textDirection: TextDirection.ltr,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'لینکی وێنە (ئارەزوومەندانە)',
                hintText: 'یان وێنە باربکە لە سەرەوە',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'سەردێڕ'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _highlight,
              decoration: const InputDecoration(labelText: 'هایلایت (٪٥٠…)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _subtitle,
              decoration: const InputDecoration(labelText: 'ژێرنووس'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cta,
              decoration: const InputDecoration(labelText: 'دوگمە'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tag,
              decoration: const InputDecoration(labelText: 'تاگ (AD / NEW)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ڕیز'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _uploading ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('پاشەکەوت'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminHeader extends ConsumerWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onLogout;
  final Widget? action;
  final bool showNotifications;

  const AdminHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onLogout,
    this.action,
    this.showNotifications = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingOrders = showNotifications
        ? ref.watch(adminPendingOrdersCountProvider)
        : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brand.withValues(alpha: 0.14),
                  AppColors.highlight.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.dashboard_customize_rounded,
              color: AppColors.brand,
              size: 24,
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (showNotifications)
            IconButton(
              onPressed: () => showAdminOrderNotifications(context, ref),
              style: IconButton.styleFrom(
                backgroundColor: pendingOrders > 0
                    ? AppColors.highlight.withValues(alpha: 0.12)
                    : AppColors.surfaceVariant,
              ),
              icon: Badge(
                isLabelVisible: pendingOrders > 0,
                backgroundColor: AppColors.highlight,
                label: Text(
                  '$pendingOrders',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                child: Icon(
                  pendingOrders > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: pendingOrders > 0
                      ? AppColors.highlight
                      : AppColors.textSecondary,
                ),
              ),
            ),
          if (action != null) action!,
          if (onLogout != null)
            IconButton(
              onPressed: onLogout,
              tooltip: 'چوونەدەرەوە',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.08),
              ),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

void showAdminOrderNotifications(BuildContext context, WidgetRef ref) {
  final pending = ref.read(adminPendingOrdersProvider);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.sheet,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.notifications_rounded, color: AppColors.brand),
                  const SizedBox(width: 10),
                  Text(
                    'ئاگادارییەکان',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (pending.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.highlight.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${pending.length} نوێ',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.highlight,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (pending.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 40,
                        color: AppColors.textTertiary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'هیچ داواکارییەکی نوێ نییە',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: pending.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final order = pending[i];
                      final shops = order.shopsLabel;
                      return Material(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.go('/admin/orders');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.highlight
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag_rounded,
                                    color: AppColors.highlight,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'کڕیار: ${order.customerName}',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'دووکان: $shops',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.brand,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${order.itemCount} بەرهەم • ${Formatters.price(order.total)}',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  Formatters.date(order.createdAt),
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/admin/orders');
                  },
                  child: const Text('بینینی هەموو داواکارییەکان'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool highlight;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final ValueChanged<ShopTier>? onTierChanged;

  const _UserCard({
    required this.user,
    this.highlight = false,
    this.onApprove,
    this.onReject,
    this.onTierChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.highlight.withValues(alpha: 0.06)
            : AppColors.surfaceVariant.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppColors.highlight.withValues(alpha: 0.35)
              : AppColors.border.withValues(alpha: 0.7),
          width: highlight ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  user.name,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusChip(status: user.approvalStatus),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'جۆری هەژمار',
            value: user.isShopOwner ? 'خاوەن دووکان' : 'کڕیار',
          ),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'ئیمەیڵ',
            value: user.email,
            ltr: true,
          ),
          if (user.phone.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'مۆبایل',
              value: user.phone,
              ltr: true,
            ),
          if ((user.location ?? '').trim().isNotEmpty || user.hasMapPin)
            _LocationMapsRow(
              label: 'ناونیشان / شوێن',
              address: (user.location ?? '').trim(),
              latitude: user.latitude,
              longitude: user.longitude,
            ),
          if (user.isShopOwner) ...[
            if ((user.shopName ?? '').trim().isNotEmpty)
              _InfoRow(
                icon: Icons.storefront_outlined,
                label: 'ناوی دووکان',
                value: user.shopName!.trim(),
              ),
            if ((user.shopAddress ?? '').trim().isNotEmpty)
              _LocationMapsRow(
                label: 'ناونیشانی دووکان',
                address: user.shopAddress!.trim(),
              ),
            if ((user.shopDescription ?? '').trim().isNotEmpty)
              _InfoRow(
                icon: Icons.notes_outlined,
                label: 'وەسفی دووکان',
                value: user.shopDescription!.trim(),
              ),
            if (onTierChanged == null)
              _InfoRow(
                icon: Icons.workspace_premium_outlined,
                label: 'پلانی دووکان',
                value: user.effectiveShopTier.labelKu,
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'پلانی دووکان',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<ShopTier>(
                        value: user.effectiveShopTier,
                        borderRadius: BorderRadius.circular(12),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.brand,
                        ),
                        items: [
                          for (final t in ShopTier.values)
                            DropdownMenuItem(
                              value: t,
                              child: Text(t.labelKu),
                            ),
                        ],
                        onChanged: (t) {
                          if (t != null) onTierChanged!(t);
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'بەرواری تۆمارکردن',
            value: Formatters.date(user.createdAt),
          ),
          if (user.isRejected &&
              (user.rejectionReason?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'هۆکار: ${user.rejectionReason}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size(0, 44),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('ڕەتکردنەوە'),
                    ),
                  ),
                if (onReject != null && onApprove != null)
                  const SizedBox(width: 10),
                if (onApprove != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 44),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('قبوڵکردن'),
                    ),
                  ),
              ],
            ),
          ],
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

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.ltr = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  textDirection: ltr ? TextDirection.ltr : null,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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

class _LocationMapsRow extends StatelessWidget {
  final String label;
  final String address;
  final double? latitude;
  final double? longitude;

  const _LocationMapsRow({
    required this.label,
    required this.address,
    this.latitude,
    this.longitude,
  });

  Future<void> _open(BuildContext context) async {
    final ok = await const MapsLauncherService().openDirections(
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'نەتوانرا Google Maps بکرێتەوە',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = latitude != null && longitude != null;
    final display = address.isNotEmpty
        ? address
        : hasPin
            ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
            : 'شوێن تۆمار نەکراوە';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      display,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              onPressed: () => _open(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand.withValues(alpha: 0.12),
                foregroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: Text(
                'کردنەوە لە Google Maps',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ApprovalStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ApprovalStatus.pending => AppColors.highlight,
      ApprovalStatus.approved => AppColors.success,
      ApprovalStatus.rejected => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.labelKu,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _BannerSizeGuide extends StatelessWidget {
  const _BannerSizeGuide();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.photo_size_select_large_rounded,
              color: AppColors.brand,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قەبارەی گونجاو بۆ سلایدەر',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'پانی ${BannerModel.recommendedWidthPx}px  ·  بەرزی ${BannerModel.recommendedHeightPx}px',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ڕێژە ${BannerModel.aspectRatio.toStringAsFixed(2)} : 1 — بۆ پڕکردنی تەواوی سلایدەر',
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
        ],
      ),
    );
  }
}

class _BannerTile extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _BannerTile({
    required this.banner,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = '${banner.title} ${banner.highlight}'.trim();
    final hasImage = banner.imageUrl.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8EEEE)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: BannerModel.aspectRatio,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(23),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: const Color(0xFFEFF5F5),
                        child: hasImage
                            ? CachedNetworkImage(
                                imageUrl: banner.imageUrl,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (_, _) => Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: AppColors.brand
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, _, _) => Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 36,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: banner.active
                                ? AppColors.success
                                : AppColors.textTertiary,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            banner.active ? 'چالاک' : 'ناچالاک',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      if (banner.tag.trim().isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              banner.tag,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'ڕیکلام بێ ناونیشان' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (banner.subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        banner.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          banner.active ? 'پیشاندان' : 'شاردنەوە',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Switch.adaptive(
                          value: banner.active,
                          activeThumbColor: AppColors.brand,
                          onChanged: onToggle,
                        ),
                        const Spacer(),
                        _BannerActionBtn(
                          icon: Icons.edit_rounded,
                          color: AppColors.brand,
                          tooltip: 'دەستکاری',
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 8),
                        _BannerActionBtn(
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.error,
                          tooltip: 'سڕینەوە',
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _BannerActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
