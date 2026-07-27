import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'page_transitions.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/auth_screen.dart';
import '../../screens/customer/home_screen.dart';
import '../../screens/customer/cart_screen.dart';
import '../../screens/customer/orders_screen.dart';
import '../../screens/customer/favorites_screen.dart';
import '../../screens/customer/product_detail_screen.dart';
import '../../screens/customer/search_screen.dart';
import '../../screens/customer/shop_storefront_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/settings/edit_profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/shop_owner/add_edit_product_screen.dart';
import '../../screens/shop_owner/shop_dashboard_screen.dart';
import '../../screens/shop_owner/shop_orders_screen.dart';
import '../../screens/shop_owner/shop_profile_screen.dart';
import '../../screens/shell/app_shell.dart';
import '../../screens/splash/splash_screen.dart';

/// Notifies GoRouter when auth changes without recreating the router.
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final location = state.matchedLocation;

      if (location == '/' || location == '/onboarding') return null;

      if (isLoading) return null;

      final isAuthRoute = location == '/auth';

      if (!isAuthenticated && !isAuthRoute && location != '/') {
        return '/auth';
      }

      if (isAuthenticated && isAuthRoute) {
        return user!.isShopOwner ? '/shop' : '/home';
      }

      if (isAuthenticated) {
        // Shop owners cannot open customer tabs (including /search).
        if (user!.isShopOwner &&
            (location.startsWith('/home') ||
                location.startsWith('/search') ||
                location.startsWith('/cart') ||
                location.startsWith('/orders') ||
                location.startsWith('/favorites') ||
                (location.startsWith('/profile') &&
                    !location.startsWith('/shop')))) {
          return '/shop';
        }
        if (user.isCustomer &&
            (location == '/shop' ||
                location.startsWith('/shop-') ||
                location.startsWith('/shop/'))) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            fadeSlidePage(child: const OnboardingScreen(), state: state),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) =>
            fadeSlidePage(child: const AuthScreen(), state: state),
      ),
      ShellRoute(
        builder: (_, __, child) => CustomerShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
          GoRoute(
            path: '/favorites',
            builder: (_, __) => const FavoritesScreen(),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (context, state) => slideFromRightPage(
          child: ProductDetailScreen(
            productId: state.pathParameters['id']!,
            heroTag: state.extra as String?,
          ),
          state: state,
        ),
      ),
      GoRoute(
        path: '/store/:shopOwnerId',
        pageBuilder: (context, state) => slideFromRightPage(
          child: ShopStorefrontScreen(
            shopOwnerId: state.pathParameters['shopOwnerId']!,
            fallbackShopName: state.uri.queryParameters['name'],
          ),
          state: state,
        ),
      ),
      ShellRoute(
        builder: (_, __, child) => ShopOwnerShell(child: child),
        routes: [
          GoRoute(
            path: '/shop',
            builder: (_, __) => const ShopDashboardScreen(),
          ),
          GoRoute(
            path: '/shop-orders',
            builder: (_, __) => const ShopOrdersScreen(),
          ),
          GoRoute(
            path: '/shop-profile',
            builder: (_, __) => const ShopProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/shop/add-product',
        pageBuilder: (context, state) => slideFromRightPage(
          child: const AddEditProductScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/shop/edit-product/:id',
        pageBuilder: (context, state) => slideFromRightPage(
          child: AddEditProductScreen(productId: state.pathParameters['id']),
          state: state,
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            slideFromRightPage(child: const SettingsScreen(), state: state),
      ),
      GoRoute(
        path: '/settings/edit-profile',
        pageBuilder: (context, state) =>
            slideFromRightPage(child: const EditProfileScreen(), state: state),
      ),
    ],
  );
});
