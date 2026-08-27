import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/admin_security.dart';
import '../core/utils/phone_utils.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instance;
  UserModel? _cached;

  Stream<UserModel?> watchCurrentUser() {
    return _api.poll(_loadCurrent);
  }

  Future<UserModel?> getCurrentUser() => _loadCurrent();

  Future<UserModel?> _loadCurrent() async {
    final token = await _api.token;
    if (token == null || token.isEmpty) {
      _cached = null;
      return null;
    }
    try {
      final data = await _api.getJson('/api/auth/me');
      final user = _user(data['user']);
      _cached = user;
      return user == null ? null : _ensureCustomerAutoApproved(user);
    } catch (e) {
      debugPrint('User profile listen failed: $e');
      await _api.setToken(null);
      _cached = null;
      return null;
    }
  }

  Future<UserModel> _ensureCustomerAutoApproved(UserModel user) async {
    // Approval is server-owned (OTP register / admin). Never self-patch approvalStatus.
    return user;
  }

  Future<UserModel> register({
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
    ApprovalStatus? approvalStatus,
  }) async {
    final normalized = PhoneUtils.normalize(phone);
    if (!PhoneUtils.isValid(normalized)) {
      throw Exception('ژمارەی مۆبایل دروست نییە (07xxxxxxxxx)');
    }
    final otp = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      throw Exception('کۆدی ٦ ژمارەیی بنووسە');
    }
    final data = await _api.postJson('/api/auth/register', {
      'name': name.trim(),
      'phone': normalized,
      'password': password,
      'code': otp,
      'role': role.name,
      'location': location,
      'shopName': shopName,
      'shopDescription': shopDescription,
      'shopAddress': shopAddress,
      'shopLogoUrl': shopLogoUrl,
      'shopCoverUrl': shopCoverUrl,
      'shopTier': shopTier?.name,
    });
    await _api.setToken(data['token'] as String?);
    final user = _user(data['user']);
    if (user == null) throw Exception('هەڵەیەک ڕوویدا');
    _cached = user;
    return user;
  }

  /// WhatsApp OTP for new account phone verification.
  Future<void> sendSignupOtp(String phone) async {
    final normalized = PhoneUtils.normalize(phone);
    if (!PhoneUtils.isValid(normalized)) {
      throw Exception('ژمارەی مۆبایل دروست نییە (07xxxxxxxxx)');
    }
    await _api.postJson('/api/auth/otp/send', {
      'phone': normalized,
      'purpose': 'signup',
    });
  }

  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    final normalized = PhoneUtils.normalize(phone);
    final data = await _api.postJson('/api/auth/login', {
      'phone': normalized,
      'password': password,
    });
    await _api.setToken(data['token'] as String?);
    var user = _user(data['user']);
    if (user == null) throw Exception('هەژمارەکە نەدۆزرایەوە');
    user = await _ensureCustomerAutoApproved(user);
    _cached = user;
    return user;
  }

  /// WhatsApp OTP login — step 1: send code to phone.
  Future<void> sendLoginOtp(String phone) async {
    final normalized = PhoneUtils.normalize(phone);
    if (!PhoneUtils.isValid(normalized)) {
      throw Exception('ژمارەی مۆبایل دروست نییە (07xxxxxxxxx)');
    }
    await _api.postJson('/api/auth/otp/send', {
      'phone': normalized,
      'purpose': 'login',
    });
  }

  /// WhatsApp OTP login — step 2: verify code and open session.
  Future<UserModel> loginWithOtp({
    required String phone,
    required String code,
  }) async {
    final normalized = PhoneUtils.normalize(phone);
    final data = await _api.postJson('/api/auth/otp/login', {
      'phone': normalized,
      'code': code.trim(),
    });
    await _api.setToken(data['token'] as String?);
    var user = _user(data['user']);
    if (user == null) throw Exception('هەژمارەکە نەدۆزرایەوە');
    user = await _ensureCustomerAutoApproved(user);
    _cached = user;
    return user;
  }

  /// Staff console only — email allowlist.
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final data = await _api.postJson('/api/auth/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    await _api.setToken(data['token'] as String?);
    var user = _user(data['user']);
    if (user == null) throw Exception('هەژمارەکە نەدۆزرایەوە');
    _cached = user;
    return user;
  }

  Future<UserModel> bootstrapAdminIfAllowed(UserModel user) async {
    if (user.isAdmin) return user;
    if (!AdminSecurity.isAllowedAdminEmail(user.email)) {
      throw Exception(
        'ئەم هەژمارە مۆڵەتی ئەدمینی نییە. تەنها admin@qopcha.com دەتوانێت بچێتە ژوورەوە.',
      );
    }
    return user;
  }

  bool get isEmailVerified => true;

  String? get currentAuthEmail => _cached?.email;

  Future<bool> reloadEmailVerified() async => true;

  Future<void> sendEmailVerification() async {}

  Future<({String? debugCode})> requestPasswordResetCode(String phone) async {
    final normalized = PhoneUtils.normalize(phone);
    if (!PhoneUtils.isValid(normalized)) {
      throw Exception('ژمارەی مۆبایل بنووسە');
    }
    await _api.postJson('/api/auth/forgot', {'phone': normalized});
    return (debugCode: null);
  }

  Future<void> resetPasswordWithCode({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    await _api.postJson('/api/auth/reset', {
      'phone': PhoneUtils.normalize(phone),
      'code': code.trim(),
      'newPassword': newPassword,
    });
  }

  Future<void> sendPasswordResetEmail(String phone) async {
    await requestPasswordResetCode(phone);
  }

  Future<void> logout() async {
    _cached = null;
    await _api.setToken(null);
  }

  Future<UserModel?> getUserById(String id) async {
    if (_cached?.id == id) return _cached;
    return _loadCurrent();
  }

  Future<void> updateProfile(UserModel user) async {
    final data = user.toJson();
    data.remove('productDiscountPercent');
    data.remove('deliveryDiscountPercent');
    data.remove('id');
    data.remove('email');
    data.remove('role');
    data.remove('approvalStatus');
    data.remove('rejectionReason');
    data.remove('shopTier');
    final res = await _api.patchJson('/api/auth/me', data);
    _cached = _user(res['user']) ?? user;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.trim().length < 6) {
      throw Exception('وشەی نهێنی نوێ لانیکەم ٦ پیت بێت');
    }
    await _api.postJson('/api/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> markApprovalNoticeSeen(String userId) async {
    await _api.patchJson('/api/auth/me', {'approvalNoticeSeen': true});
  }

  Future<void> markNotificationsSeen(String userId) async {
    await _api.patchJson('/api/auth/me', {
      'lastNotificationsSeenAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markDeliveredOrdersSeen(String userId) async {
    await markOrderTabsSeen(userId, const ['delivered']);
  }

  Future<void> markOrderTabsSeen(String userId, Iterable<String> tabs) async {
    final keys = tabs.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet();
    if (keys.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      for (final tab in keys) 'orderTabsSeenAt.$tab': now,
    };
    if (keys.contains('delivered')) {
      data['lastDeliveredOrdersSeenAt'] = now;
    }
    await _api.patchJson('/api/auth/me', data);
  }

  UserModel? _user(Object? raw) {
    if (raw is! Map) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(raw));
  }
}
