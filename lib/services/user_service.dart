import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Singleton — kullanıcı profil verilerini SharedPreferences ve Firestore ile yönetir.
class UserService {
  UserService._();
  static final UserService _instance = UserService._();
  factory UserService() => _instance;

  static const _key = 'user_profile';

  /// Reactive bildirim — profil değişince dinleyicilere bildirir.
  static final ValueNotifier<UserProfile> profile =
      ValueNotifier(const UserProfile());

  // ── Firestore yolu ────────────────────────────────────────────────────────
  DocumentReference? get _firestoreDoc {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('content')
        .doc('user_profile');
  }

  Future<UserProfile> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1) Firestore'dan senkronize et (giriş yapılmışsa)
    final doc = _firestoreDoc;
    if (doc != null) {
      try {
        final snap = await doc.get(const GetOptions(source: Source.server)).timeout(const Duration(seconds: 6));
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          // Firestore'daki veriyi yerele yaz
          await prefs.setString(_key, json.encode(data));
        }
      } catch (_) {
        // Hata durumunda yerel veriye güven
      }
    }

    // 2) Yerelden (güncellenmiş veya eski) yükle
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final user = UserProfile.fromJson(
            json.decode(raw) as Map<String, dynamic>);
        profile.value = user;
        return user;
      } catch (_) {
        return const UserProfile();
      }
    }
    return const UserProfile();
  }

  Future<void> saveUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(user.toJson());
    
    // Yerel kaydet
    await prefs.setString(_key, jsonStr);
    profile.value = user;

    // Firestore yedekle
    _backupToFirestore(user.toJson());
  }

  void _backupToFirestore(Map<String, dynamic> data) {
    final doc = _firestoreDoc;
    if (doc == null) return;
    doc.set(data, SetOptions(merge: true)).catchError((e) {
      debugPrint('🚨 User backup failed: $e');
    });
  }

  /// Kullanıcı giriş yaptığında Firestore'dan taze veriyi çekmek için çağrılır
  Future<void> onUserLogin() async {
    await loadUser();
  }
}
