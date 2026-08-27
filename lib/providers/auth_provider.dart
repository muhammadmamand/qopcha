import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/admin_security.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool emailVerified;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.emailVerified = false,
  });

  bool get isAuthenticated => user != null;

  /// Email verification is turned off for now.
  bool get needsEmailVerification => false;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? emailVerified,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  StreamSubscription<UserModel?>? _userSub;

  AuthNotifier(this._authService) : super(const AuthState(isLoading: true)) {
    _bindUserStream();
  }

  void _bindUserStream() {
    _userSub?.cancel();
    _userSub = _authService.watchCurrentUser().listen(
      (user) {
        state = AuthState(
          user: user,
          isLoading: false,
          emailVerified: user == null ? false : _authService.isEmailVerified,
        );
        _syncPush(user);
      },
      onError: (e) {
        state = AuthState(isLoading: false, error: e.toString());
      },
    );
  }

  Future<void> _syncPush(UserModel? user) async {
    try {
      await PushNotificationService.instance.syncForUser(user);
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('Push sync failed: $e');
        return true;
      }());
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(phone: phone, password: password);

      // Admins must use the separate staff console — not the public app login.
      if (user.isAdmin) {
        await _authService.logout();
        state = const AuthState(
          isLoading: false,
          error:
              'ئەدمین ناتوانێت لەم پەڕەیە بچێتە ژوورەوە — پانێڵی بەڕێوەبردن بەکاربهێنە',
        );
        return false;
      }

      state = AuthState(
        user: user,
        isLoading: false,
        emailVerified: _authService.isEmailVerified,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Send WhatsApp OTP for public app login.
  Future<String?> sendLoginOtp(String phone) async {
    try {
      await _authService.sendLoginOtp(phone);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Complete login with WhatsApp OTP code.
  Future<bool> loginWithOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.loginWithOtp(phone: phone, code: code);

      if (user.isAdmin) {
        await _authService.logout();
        state = const AuthState(
          isLoading: false,
          error:
              'ئەدمین ناتوانێت لەم پەڕەیە بچێتە ژوورەوە — پانێڵی بەڕێوەبردن بەکاربهێنە',
        );
        return false;
      }

      state = AuthState(
        user: user,
        isLoading: false,
        emailVerified: _authService.isEmailVerified,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Dedicated admin console login. Rejects non-admins and non-allowlisted emails.
  Future<bool> loginAsAdmin(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (!AdminSecurity.isAllowedAdminEmail(email)) {
        state = state.copyWith(
          isLoading: false,
          error:
              'ئەم هەژمارە مۆڵەتی ئەدمینی نییە. تەنها admin@qopcha.com دەتوانێت بچێتە ژوورەوە.',
        );
        return false;
      }

      var user = await _authService.loginWithEmail(email: email, password: password);
      if (!user.isAdmin) {
        user = await _authService.bootstrapAdminIfAllowed(user);
      }

      if (!user.isAdmin || !AdminSecurity.isAllowedAdminEmail(user.email)) {
        await _authService.logout();
        state = const AuthState(
          isLoading: false,
          error:
              'ئەم هەژمارە مۆڵەتی ئەدمینی نییە. تەنها admin@qopcha.com دەتوانێت بچێتە ژوورەوە.',
        );
        return false;
      }

      state = AuthState(
        user: user,
        isLoading: false,
        emailVerified: _authService.isEmailVerified,
      );
      return true;
    } catch (e) {
      await _authService.logout();
      state = AuthState(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required String code,
    required UserRole role,
    String? location,
    String? shopName,
    String? shopDescription,
    String? shopAddress,
    String? shopLogoUrl,
    String? shopCoverUrl,
    ShopTier? shopTier,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.register(
        name: name,
        phone: phone,
        password: password,
        code: code,
        role: role,
        location: location,
        shopName: shopName,
        shopDescription: shopDescription,
        shopAddress: shopAddress,
        shopLogoUrl: shopLogoUrl,
        shopCoverUrl: shopCoverUrl,
        shopTier: shopTier,
      );
      state = AuthState(
        user: user,
        isLoading: false,
        emailVerified: _authService.isEmailVerified,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Send WhatsApp OTP to verify phone during signup.
  Future<String?> sendSignupOtp(String phone) async {
    try {
      await _authService.sendSignupOtp(phone);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> logout() async {
    try {
      await PushNotificationService.instance.clearForLogout();
    } catch (_) {}
    await _authService.logout();
    state = const AuthState();
  }

  Future<bool> updateProfile(UserModel user) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.updateProfile(user);
      state = AuthState(
        user: user,
        isLoading: false,
        emailVerified: _authService.isEmailVerified,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Returns `null` on success, or a Kurdish error message on failure.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } catch (e) {
      var msg = e.toString();
      msg = msg.replaceFirst(RegExp(r'^Exception:\s*'), '');
      msg = msg.replaceFirst(RegExp(r'^\.'), '');
      if (msg.toLowerCase().contains('internal error') ||
          msg.trim().isEmpty) {
        return 'وشەی نهێنی ئێستات هەڵەیە';
      }
      return msg;
    }
  }

  /// Forgot password — sends a 6-digit WhatsApp OTP.
  /// Returns `(error, debugCode)`.
  Future<({String? error, String? debugCode})> requestPasswordResetCode(
    String phone,
  ) async {
    try {
      final result = await _authService.requestPasswordResetCode(phone);
      return (error: null, debugCode: result.debugCode);
    } catch (e) {
      return (
        error: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
        debugCode: null,
      );
    }
  }

  /// Completes password reset with phone OTP + new password.
  Future<String?> resetPasswordWithCode({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _authService.resetPasswordWithCode(
        phone: phone,
        code: code,
        newPassword: newPassword,
      );
      return null;
    } catch (e) {
      return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    }
  }

  /// @deprecated Prefer [requestPasswordResetCode].
  Future<String?> sendPasswordResetEmail(String phone) async {
    try {
      await _authService.sendPasswordResetEmail(phone);
      return null;
    } catch (e) {
      return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    }
  }

  /// Resend verification email. Returns error message or null.
  Future<String?> resendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
      return null;
    } catch (e) {
      return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    }
  }

  /// Reload Auth user after the user taps the email link.
  /// Returns `true` if verified.
  Future<bool> checkEmailVerified() async {
    try {
      final verified = await _authService.reloadEmailVerified();
      state = AuthState(
        user: state.user,
        isLoading: false,
        emailVerified: verified,
      );
      return verified;
    } catch (_) {
      return false;
    }
  }

  Future<void> markApprovalNoticeSeen() async {
    final user = state.user;
    if (user == null || user.approvalNoticeSeen) return;
    await _authService.markApprovalNoticeSeen(user.id);
    state = AuthState(
      user: user.copyWith(approvalNoticeSeen: true),
      isLoading: false,
      emailVerified: state.emailVerified,
    );
  }

  Future<void> markNotificationsSeen() async {
    final user = state.user;
    if (user == null) return;
    final now = DateTime.now();
    await _authService.markNotificationsSeen(user.id);
    state = AuthState(
      user: user.copyWith(lastNotificationsSeenAt: now),
      isLoading: false,
      emailVerified: state.emailVerified,
    );
  }

  Future<void> markDeliveredOrdersSeen() =>
      markOrderTabsSeen(const ['delivered']);

  Future<void> markOrderTabsSeen(Iterable<String> tabs) async {
    final user = state.user;
    if (user == null) return;
    final keys = tabs.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet();
    if (keys.isEmpty) return;
    final now = DateTime.now();
    final next = Map<String, DateTime>.from(user.orderTabsSeenAt);
    for (final tab in keys) {
      next[tab] = now;
    }
    await _authService.markOrderTabsSeen(user.id, keys);
    state = AuthState(
      user: user.copyWith(
        orderTabsSeenAt: next,
        lastDeliveredOrdersSeenAt:
            keys.contains('delivered') ? now : user.lastDeliveredOrdersSeenAt,
      ),
      isLoading: false,
      emailVerified: state.emailVerified,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isShopOwnerProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isShopOwner ?? false;
});
