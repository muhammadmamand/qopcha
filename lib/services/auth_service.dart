import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<UserModel?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return getUserById(fbUser.uid);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? location,
    String? shopName,
    String? shopDescription,
    String? shopAddress,
    ShopTier? shopTier,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      final user = UserModel(
        id: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        location: location?.trim().isEmpty == true ? null : location?.trim(),
        shopName: shopName,
        shopDescription: shopDescription,
        shopAddress: shopAddress,
        shopTier: role == UserRole.shopOwner
            ? (shopTier ?? ShopTier.silver)
            : null,
        createdAt: DateTime.now(),
      );

      await _users.doc(uid).set(user.toJson());
      await credential.user!.updateDisplayName(name.trim());
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await getUserById(credential.user!.uid);
      if (user == null) {
        throw Exception('هەژمارەکە نەدۆزرایەوە');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserById(String id) async {
    final snap = await _users.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    final data = Map<String, dynamic>.from(snap.data()!);
    data['id'] = snap.id;
    return UserModel.fromJson(data);
  }

  Future<void> updateProfile(UserModel user) async {
    await _users.doc(user.id).set(user.toJson(), SetOptions(merge: true));
    final current = _auth.currentUser;
    if (current != null && current.uid == user.id) {
      await current.updateDisplayName(user.name);
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => 'ئەم ئیمەیڵە پێشتر تۆمارکراوە',
      'invalid-email' => 'ئیمەیڵ هەڵەیە',
      'weak-password' => 'وشەی نهێنی لاوازە (لانیکەم ٦ پیت)',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'ئیمەیڵ یان وشەی نهێنی هەڵەیە',
      'too-many-requests' => 'هەوڵی زۆر درا — دواتر هەوڵبدەرەوە',
      'network-request-failed' => 'پەیوەندی ئینتەرنێت نییە',
      _ => e.message ?? 'هەڵەیەک ڕوویدا',
    };
  }
}
