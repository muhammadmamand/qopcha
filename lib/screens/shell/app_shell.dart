import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/premium_bottom_nav.dart';

export 'profile_screen.dart';

class CustomerShell extends ConsumerStatefulWidget {
  final Widget child;

  const CustomerShell({super.key, required this.child});

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    // Order matches screenshot layout: Home … Profile (bulb).
    if (location.startsWith('/home')) {
      _currentIndex = 0;
    } else if (location.startsWith('/search')) {
      _currentIndex = 1;
    } else if (location.startsWith('/favorites')) {
      _currentIndex = 2;
    } else if (location.startsWith('/cart')) {
      _currentIndex = 3;
    } else if (location.startsWith('/profile')) {
      _currentIndex = 4;
    }

    final cartCount = ref.watch(cartItemCountProvider);
    final animateCartEmptyIcon = cartCount == 0 && _currentIndex == 3;

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            context.go('/home');
          } else if (index == 1) {
            context.go('/search');
          } else if (index == 2) {
            context.go('/favorites');
          } else if (index == 3) {
            context.go('/cart');
          } else if (index == 4) {
            context.go('/profile');
          }
        },
        badges: [null, null, null, cartCount > 0 ? cartCount : null, null],
        animatedIndexes: animateCartEmptyIcon ? const [3] : const [],
        // Layout: Home · Search | ♥ center | Cart · Profile
        items: const [
          NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'سەرەکی',
          ),
          NavItem(
            icon: Icons.search_rounded,
            activeIcon: Icons.search_rounded,
            label: 'گەڕان',
          ),
          NavItem(
            icon: Icons.favorite_border_rounded,
            activeIcon: Icons.favorite_rounded,
            label: 'دڵخواز',
          ),
          NavItem(
            icon: Icons.shopping_bag_outlined,
            activeIcon: Icons.shopping_bag_rounded,
            label: 'سەبەتە',
          ),
          NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'پڕۆفایل',
          ),
        ],
      ),
    );
  }
}

class ShopOwnerShell extends ConsumerStatefulWidget {
  final Widget child;

  const ShopOwnerShell({super.key, required this.child});

  @override
  ConsumerState<ShopOwnerShell> createState() => _ShopOwnerShellState();
}

class _ShopOwnerShellState extends ConsumerState<ShopOwnerShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

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

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: PremiumBottomNav(
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
        items: const [
          NavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_outlined,
            label: 'داشبۆرد',
          ),
          NavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_outlined,
            label: 'داواکاری',
          ),
          NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_outline_rounded,
            label: 'پڕۆفایل',
          ),
        ],
      ),
      // Keep add-product off the center so it doesn't collide with the notched FAB.
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/shop/add-product'),
              elevation: 12,
              icon: const Icon(Icons.add_rounded),
              label: const Text('بەرهەمی نوێ'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
