import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../../core/theme/app_theme.dart';
import '../../core/router/page_transitions.dart';
import '../../core/utils/shop_navigation.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shell_navigation_provider.dart';
import '../../widgets/floral_scene_wrapper.dart';
import '../../widgets/premium_bottom_nav.dart';

export 'profile_screen.dart';

/// Desktop/Skia capture every frame fights vsync and logs
/// "Reported frame time is older…". Keep realtime only on mobile Impeller.
bool get _liquidGlassRealtime {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class CustomerShell extends ConsumerStatefulWidget {
  final Widget child;
  final String? routePath;

  const CustomerShell({super.key, required this.child, this.routePath});

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Keep nav / scaffold colors fresh when theme changes.
    ref.watch(appSettingsProvider.select((s) => s.themeMode));
    ref.watch(appSettingsProvider.select((s) => s.colorTheme));
    final lang = ref.watch(appSettingsProvider.select((s) => s.language));
    final goState = GoRouterState.of(context);
    final location = (widget.routePath?.isNotEmpty == true)
        ? widget.routePath!
        : (goState.uri.path.isNotEmpty
            ? goState.uri.path
            : goState.matchedLocation);

    // Order matches screenshot layout: Home … Profile (bulb).
    if (location.startsWith('/home')) {
      _currentIndex = 0;
    } else if (location.startsWith('/fabrics')) {
      _currentIndex = 1;
    } else if (location.startsWith('/discounts')) {
      _currentIndex = 2;
    } else if (location.startsWith('/cart')) {
      _currentIndex = 3;
    } else if (location.startsWith('/profile') ||
        location.startsWith('/favorites')) {
      // Favorites is opened from profile, not the center tab.
      _currentIndex = 4;
    }

    final cartCount = ref.watch(cartItemCountProvider);
    final animateCartEmptyIcon = cartCount == 0 && _currentIndex == 3;
    // Keep local system banners in sync with inbox polling.
    ref.watch(notificationLocalAlertBridgeProvider);
    final hideNav = isShellOverlayLocation(location) ||
        ref.watch(shellModalChromeHiddenProvider);

    return LiquidGlassScaffold(
      backgroundColor: AppColors.surface,
      pixelRatio: 1,
      useSync: true,
      realTimeCapture: _liquidGlassRealtime,
      body: FloralSceneWrapper(child: widget.child),
      bottomNavigationBar: hideNav
          ? null
          : PremiumBottomNav(
              context: context,
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 0 && location.startsWith('/home')) {
                  triggerHomeScrollToTop(ref);
                }
                setState(() => _currentIndex = index);
                if (index == 0) {
                  context.go('/home');
                } else if (index == 1) {
                  context.go('/fabrics');
                } else if (index == 2) {
                  context.go('/discounts');
                } else if (index == 3) {
                  context.go('/cart');
                } else if (index == 4) {
                  context.go('/profile');
                }
              },
              badges: [null, null, null, cartCount > 0 ? cartCount : null, null],
              animatedIndexes: animateCartEmptyIcon ? const [3] : const [],
              // Layout: Home · Search | Offers center | Cart · Profile
              items: [
                NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: tr(lang, 'سەرەکی', 'Home', 'الرئيسية'),
                ),
                NavItem(
                  icon: Icons.texture_outlined,
                  activeIcon: Icons.texture_rounded,
                  assetIcon: 'assets/images/category/fabric.png',
                  label: tr(lang, 'قوماش', 'Fabrics', 'الأقمشة'),
                ),
                NavItem(
                  icon: Icons.local_offer_outlined,
                  activeIcon: Icons.local_offer_rounded,
                  label: tr(lang, 'داشکاندن', 'Offers', 'عروض'),
                ),
                NavItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: tr(lang, 'سەبەتە', 'Cart', 'السلة'),
                ),
                NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: tr(lang, 'پڕۆفایل', 'Profile', 'حسابي'),
                ),
              ],
            ),
    );
  }
}

class ShopOwnerShell extends ConsumerStatefulWidget {
  final Widget child;
  final String? routePath;

  const ShopOwnerShell({super.key, required this.child, this.routePath});

  @override
  ConsumerState<ShopOwnerShell> createState() => _ShopOwnerShellState();
}

class _ShopOwnerShellState extends ConsumerState<ShopOwnerShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Keep nav / scaffold colors fresh when theme changes.
    ref.watch(appSettingsProvider.select((s) => s.themeMode));
    ref.watch(appSettingsProvider.select((s) => s.colorTheme));
    final lang = ref.watch(appSettingsProvider.select((s) => s.language));
    final goState = GoRouterState.of(context);
    // Prefer ShellRoute-provided path — most reliable for overlay chrome.
    final location = (widget.routePath?.isNotEmpty == true)
        ? widget.routePath!
        : (goState.uri.path.isNotEmpty
            ? goState.uri.path
            : goState.matchedLocation);

    if (location.startsWith('/shop-orders')) {
      _currentIndex = 1;
    } else if (location.startsWith('/shop-profile')) {
      _currentIndex = 2;
    } else if (location.startsWith('/shop') &&
        !location.contains('add') &&
        !location.contains('edit')) {
      _currentIndex = 0;
    }

    final pendingOrders = ref.watch(shopPendingOrdersCountProvider);
    ref.watch(notificationLocalAlertBridgeProvider);
    final hideNav = isShellOverlayLocation(location) ||
        isShellOverlayLocation(goState.matchedLocation) ||
        isShellOverlayLocation(goState.uri.path) ||
        ref.watch(shellModalChromeHiddenProvider);

    return LiquidGlassScaffold(
      backgroundColor: AppColors.surface,
      pixelRatio: 1,
      useSync: true,
      realTimeCapture: _liquidGlassRealtime,
      body: FloralSceneWrapper(child: widget.child),
      bottomNavigationBar: hideNav
          ? null
          : PremiumBottomNav(
              context: context,
              currentIndex: _currentIndex,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/shop');
                  case 1:
                    context.go('/shop-orders');
                  case 2:
                    context.go('/shop-profile');
                }
              },
              badges: [null, pendingOrders > 0 ? pendingOrders : null, null],
              items: [
                NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: tr(lang, 'داشبۆرد', 'Dashboard', 'لوحة التحكم'),
                ),
                NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: tr(lang, 'داواکاری', 'Orders', 'الطلبات'),
                ),
                NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: tr(lang, 'پڕۆفایل', 'Profile', 'حسابي'),
                ),
              ],
            ),
      // Never show the shell "Add" FAB on the product form itself.
      floatingActionButton: (!hideNav && _currentIndex == 0)
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton.extended(
                onPressed: () => openShopAddProductChooser(context, ref),
                elevation: 8,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  tr(lang, 'زیادکردن', 'Add', 'إضافة'),
                ),
              ),
            )
          : null,
      floatingActionButtonAlignment: AlignmentDirectional.bottomEnd,
    );
  }
}
