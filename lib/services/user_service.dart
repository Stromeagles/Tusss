import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Singleton — kullanıcı profil verilerini SharedPreferences ile yönetir.
class UserService {
  UserService._();
  static final UserService _instance = UserService._();
  factory UserService() => _instance;

  static const _key = 'user_profile';

  /// Reactive bildirim — profil değişince dinleyicilere bildirir.
  static final ValueNotifier<UserProfile> profile =
      ValueNotifier(const UserProfile());

  Future<UserProfile> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final user = UserProfile.fromJson(
          json.decode(raw) as Map<String, dynamic>);
      profile.value = user;
      return user;
    }
    return const UserProfile();
  }

  Future<void> saveUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(user.toJson()));
    profile.value = user;
  }
}
