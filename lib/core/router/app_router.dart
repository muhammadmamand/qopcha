import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'page_transitions.dart';
import '../../core/constants/admin_security.dart';
import '../../core/platform/app_host.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/admin/admin_content_screen.dart';
import '../../screens/admin/admin_discounts_screen.dart';
import '../../screens/admin/admin_orders_screen.dart';
import '../../screens/admin/admin_leaders_screen.dart';
import '../../screens/admin/admin_products_screen.dart';
import '../../screens/admin/admin_reports_screen.dart';
import '../../screens/auth/admin_login_screen.dart';
import '../../screens/auth/auth_screen.dart';
import '../../screens/auth/email_verification_screen.dart';
import '../../screens/auth/forgot_password_otp_screen.dart';
import '../../screens/auth/pending_approval_screen.dart';
import '../../screens/customer/home_screen.dart';
import '../../screens/customer/cart_screen.dart';
import '../../screens/customer/orders_screen.dart';
import '../../screens/customer/discounts_screen.dart';
import '../../screens/customer/fabrics_screen.dart';
import '../../screens/customer/favorites_screen.dart';
import '../../screens/customer/notifications_screen.dart';
import '../../screens/customer/product_detail_screen.dart';
import '../../screens/customer/shop_storefront_screen.dart';
import '../../screens/settings/addresses_screen.dart';
import '../../screens/settings/body_measurements_screen.dart';
import '../../screens/settings/edit_profile_screen.dart';
import '../../screens/settings/legal_document_screen.dart';
import '../../screens/settings/payment_methods_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/shop_owner/add_edit_product_screen.dart';
import '../../screens/shop_owner/shop_dashboard_screen.dart';
import '../../screens/shop_owner/shop_orders_screen.dart';
import '../../screens/shop_owner/shop_profile_screen.dart';
import '../../screens/shell/app_shell.dart';
import '../../screens/splash/splash_screen.dart';

/// Notifies GoRouter when auth *navigation* inputs change.
/// Ignores noisy profile field updates that would rematch routes unnecessarily.
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      final prevUser = prev?.user;
      final nextUser = next.user;
      final changed = prev?.isLoading != next.isLoading ||
          prev?.isAuthenticated != next.isAuthenticated ||
          prev?.emailVerified != next.emailVerified ||
          prevUser?.id != nextUser?.id ||
          prevUser?.role != nextUser?.role ||
          prevUser?.approvalStatus != nextUser?.approvalStatus;
      if (changed) notifyListeners();
    });
  }
}

String _homeForUser(UserModel user) {
  if (user.isAdmin) return '/admin';
  if (user.isRejected) return '/pending';
  if (user.isPending && user.isShopOwner) return '/pending';
  if (user.isShopOwner) return '/shop';
  return '/home';
}

bool _isBrowseAllowedForPendingCustomer(String location) {
  return location.startsWith('/home') ||
      location.startsWith('/fabrics') ||
      location.startsWith('/product') ||
      location.startsWith('/store') ||
      location.startsWith('/favorites') ||
      location.startsWith('/discounts') ||
      location.startsWith('/profile') ||
      location.startsWith('/cart') ||
      location.startsWith('/settings') ||
      location.startsWith('/notifications') ||
      location.startsWith('/orders');
}

/// Guest can browse the store without an account.
bool _isGuestBrowseRoute(String location) {
  return location.startsWith('/home') ||
      location.startsWith('/fabrics') ||
      location.startsWith('/product') ||
      location.startsWith('/store') ||
      location.startsWith('/favorites') ||
      location.startsWith('/discounts') ||
      location.startsWith('/cart') ||
      location.startsWith('/profile') ||
      location.startsWith('/notifications') ||
      location.startsWith('/orders') ||
      location == '/settings';
}

/// One persistent shell so bottom-nav animation state survives tab switches.
Widget _roleShell(GoRouterState state, Widget child) {
  final loc = state.matchedLocation;
  if (loc.startsWith('/admin')) {
    return AdminShell(child: child);
  }
  if (loc.startsWith('/shop')) {
    return ShopOwnerShell(child: child);
  }
  return CustomerShell(child: child);
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh(ref);
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  // Overlay shell: fullscreen pushes (notifications, product, settings…).
  final overlayNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'overlay');
  // Tab shell: bottom navigation pages.
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final location = state.matchedLocation;
      final webAdmin = AppHost.isAdminWebConsole;

      // Splash handles its own navigation.
      if (location == '/') return null;
      if (location == '/onboarding') {
        return webAdmin ? AdminSecurity.loginPath : '/auth';
      }

      if (isLoading) return null;

      final isAuthRoute = location == '/auth';
      final isForgotRoute = location == '/auth/forgot-password';
      final isAdminLoginRoute = location == AdminSecurity.loginPath;
      final isPendingRoute = location == '/pending';
      final isVerifyRoute = location == '/verify-email';
      final isLegalRoute = location.startsWith('/legal');
      // `/admin` panel only — not the obscure admin login path.
      final isAdminRoute =
          location.startsWith('/admin') && !isAdminLoginRoute;

      // ---- Web = Admin Console only ----
      if (webAdmin) {
        if (!isAuthenticated || user == null) {
          if (isAdminLoginRoute) return null;
          return AdminSecurity.loginPath;
        }
        if (!user.isAdmin) {
          // Kick non-admin sessions off the web console.
          Future.microtask(() => ref.read(authProvider.notifier).logout());
          return AdminSecurity.loginPath;
        }
        if (isAdminLoginRoute || isAuthRoute || isForgotRoute || isVerifyRoute) {
          return '/admin';
        }
        if (!isAdminRoute) return '/admin';
        return null;
      }

      if (!isAuthenticated &&
          !isAuthRoute &&
          !isForgotRoute &&
          !isLegalRoute &&
          !isAdminLoginRoute &&
          location != '/') {
        if (_isGuestBrowseRoute(location)) return null;
        return '/auth';
      }

      if (isAuthenticated && user != null && authState.needsEmailVerification) {
        if (!isVerifyRoute) return '/verify-email';
        return null;
      }

      if (isAuthenticated && isVerifyRoute && !authState.needsEmailVerification) {
        return _homeForUser(user!);
      }

      if (isAuthenticated && (isAuthRoute || isAdminLoginRoute) && !isForgotRoute) {
        return _homeForUser(user!);
      }

      if (isAuthenticated && user != null) {
        if (user.isRejected &&
            !isPendingRoute &&
            !isAuthRoute &&
            !isForgotRoute &&
            !isAdminLoginRoute) {
          return '/pending';
        }

        if (user.isPending &&
            user.isShopOwner &&
            !isPendingRoute &&
            !isAuthRoute &&
            !isForgotRoute &&
            !isAdminLoginRoute) {
          return '/pending';
        }
        if (user.isPending &&
            user.isCustomer &&
            !isPendingRoute &&
            !isAuthRoute &&
            !isForgotRoute &&
            !isAdminLoginRoute &&
            !_isBrowseAllowedForPendingCustomer(location)) {
          return '/home';
        }
        if (user.isPending && user.isCustomer && isPendingRoute) {
          return '/home';
        }

        if (user.isApproved && isPendingRoute) {
          return _homeForUser(user);
        }
        // Admin stays in admin panel only.
        if (user.isAdmin && !isAdminRoute) {
          return '/admin';
        }
        if (!user.isAdmin && isAdminRoute) {
          return _homeForUser(user);
        }
        if (user.isShopOwner &&
            user.isApproved &&
            (location.startsWith('/home') ||
                location.startsWith('/fabrics') ||
                location.startsWith('/cart') ||
                location.startsWith('/orders') ||
                location.startsWith('/favorites') ||
                location.startsWith('/discounts') ||
                (location.startsWith('/profile') &&
                    !location.startsWith('/shop')))) {
          return '/shop';
        }
        if (user.isCustomer &&
            user.isApproved &&
            (location == '/shop' ||
                location.startsWith('/shop-') ||
                (location.startsWith('/shop/') &&
                    !location.startsWith('/shop/add-product') &&
                    !location.startsWith('/shop/edit-product')))) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final next = state.uri.queryParameters['next'];
          return fadeSlidePage(
            child: AuthScreen(
              initialTab: tab == 'signup' ? 1 : 0,
              nextPath: next,
            ),
            state: state,
          );
        },
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (context, state) {
          final phone = state.uri.queryParameters['phone'];
          return fadeSlidePage(
            child: ForgotPasswordOtpScreen(initialPhone: phone),
            state: state,
          );
        },
      ),
      GoRoute(
        path: AdminSecurity.loginPath,
        pageBuilder: (context, state) =>
            fadeSlidePage(child: const AdminLoginScreen(), state: state),
      ),
      GoRoute(
        path: '/pending',
        pageBuilder: (context, state) =>
            fadeSlidePage(child: const PendingApprovalScreen(), state: state),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) => fadeSlidePage(
          child: const EmailVerificationScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/legal/about',
        pageBuilder: (context, state) => slideFromRightPage(
          child: const LegalDocumentScreen(kind: LegalDocumentKind.about),
          state: state,
        ),
      ),
      GoRoute(
        path: '/legal/terms',
        pageBuilder: (context, state) => slideFromRightPage(
          child: const LegalDocumentScreen(kind: LegalDocumentKind.terms),
          state: state,
        ),
      ),
      GoRoute(
        path: '/legal/privacy',
        pageBuilder: (context, state) => slideFromRightPage(
          child: const LegalDocumentScreen(kind: LegalDocumentKind.privacy),
          state: state,
        ),
      ),
      // Outer shell = overlay navigator (fullscreen pushes).
      // Inner shell = bottom-nav tabs.
      // This avoids go_router key collisions from sibling ShellRoute + root push.
      ShellRoute(
        navigatorKey: overlayNavigatorKey,
        pageBuilder: (context, state, child) => NoTransitionPage<void>(
          key: const ValueKey<String>('overlay-shell'),
          child: child,
        ),
        routes: [
          ShellRoute(
            navigatorKey: shellNavigatorKey,
            pageBuilder: (context, state, child) => NoTransitionPage<void>(
              key: const ValueKey<String>('app-shell'),
              child: _roleShell(state, child),
            ),
            routes: [
              GoRoute(
                path: '/admin',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const AdminAccountsScreen(),
                ),
              ),
              GoRoute(
                path: '/admin/leaders',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const AdminLeadersScreen(),
                ),
              ),
              GoRoute(
                path: '/admin/orders',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const AdminOrdersScreen(
                    board: AdminOrderBoard.inbox,
                  ),
                ),
              ),
              GoRoute(
                path: '/admin/delivery',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const AdminOrdersScreen(
                    board: AdminOrderBoard.delivery,
                  ),
                ),
              ),
              GoRoute(
                path: '/admin/reports',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const AdminReportsScreen(),
                ),
              ),
              GoRoute(
                path: '/admin/products',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const AdminProductsScreen(),
                ),
              ),
              GoRoute(
                path: '/admin/discounts',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const AdminDiscountsScreen(),
                ),
              ),
              GoRoute(
                path: '/admin/banners',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const AdminBannersScreen(),
                ),
              ),
              GoRoute(
                path: '/admin/content',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const AdminContentScreen(),
                ),
              ),
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const HomeScreen(),
                ),
              ),
              GoRoute(
                path: '/fabrics',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const FabricsScreen(),
                ),
              ),
              GoRoute(
                path: '/cart',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const CartScreen(),
                ),
              ),
              GoRoute(
                path: '/orders',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: OrdersScreen(
                    initialTab: state.uri.queryParameters['tab'],
                  ),
                ),
              ),
              GoRoute(
                path: '/discounts',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const DiscountsScreen(),
                ),
              ),
              GoRoute(
                path: '/favorites',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const FavoritesScreen(),
                ),
              ),
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const ProfileScreen(),
                ),
              ),
              GoRoute(
                path: '/shop',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const ShopDashboardScreen(),
                ),
              ),
              GoRoute(
                path: '/shop-orders',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const ShopOrdersScreen(),
                ),
              ),
              GoRoute(
                path: '/shop-profile',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  key: shellTabKey(state),
                  child: const ShopProfileScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            parentNavigatorKey: overlayNavigatorKey,
            path: '/notifications',
            pageBuilder: (context, state) => slideFromRightPage(
              child: const NotificationsScreen(),
              state: state,
            ),
          ),
          GoRoute(
            parentNavigatorKey: overlayNavigatorKey,
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
            parentNavigatorKey: overlayNavigatorKey,
            path: '/store/:shopOwnerId',
            pageBuilder: (context, state) => slideFromRightPage(
              child: ShopStorefrontScreen(
                shopOwnerId: state.pathParameters['shopOwnerId']!,
                fallbackShopName: state.uri.queryParameters['name'],
              ),
              state: state,
            ),
          ),
          GoRoute(
            parentNavigatorKey: overlayNavigatorKey,
            path: '/shop/add-product',
            pageBuilder: (context, state) => slideFromRightPage(
              child: AddEditProductScreen(
                isFabric: state.uri.queryParameters['kind'] == 'fabric',
              ),
              state: state,
            ),
          ),
          GoRoute(
            parentNavigatorKey: overlayNavigatorKey,
            path: '/shop/edit-product/:id',
            pageBuilder: (context, state) => slideFromRightPage(
              child:
                  AddEditProductScreen(productId: state.pathParameters['id']),
              state: state,
            ),
          ),
          GoRoute(
            parentNavigatorKey: overlayNavigatorKey,
            path: '/settings',
            pageBuilder: (context, state) =>
                slideFromRightPage(child: const SettingsScreen(), state: state),
          ),
          GoRoute(
            parentNavigatorKey: overlayNavigatorKey,
            path: '/settings/edit-profile',
            pageBuilder: (context, state) => slideFromRightPage(
              child: const EditProfileScreen(),
              state: state,
            ),
          ),
          GoRoute(
            parentNavigatorKey: overlayNavigatorKey,
            path: '/settings/addresses',
            pageBuilder: (context, state) => slideFromRightPage(
              child: const AddressesScreen(),
              state: state,
            ),
          ),
          GoRoute(
            parentNavigatorKey: overlayNavigatorKey,
            path: '/settings/measurements',
            pageBuilder: (context, state) => slideFromRightPage(
              child: const BodyMeasurementsScreen(),
              state: state,
            ),
          ),
          GoRoute(
            parentNavigatorKey: overlayNavigatorKey,
            path: '/settings/payment-methods',
            pageBuilder: (context, state) => slideFromRightPage(
              child: const PaymentMethodsScreen(),
              state: state,
            ),
          ),
        ],
      ),
    ],
  );
});
