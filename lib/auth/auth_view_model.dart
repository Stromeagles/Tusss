import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthMode { login, signup }

enum PasswordStrength { weak, medium, strong }

class AuthViewModel extends ChangeNotifier {
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyEmail = 'auth_email';
  static const _keyName = 'auth_name';

  // ── Form fields ───────────────────────────────────────────────────────────
  String name            = '';
  String email           = '';
  String password        = '';
  String confirmPassword = '';

  // ── UI state ──────────────────────────────────────────────────────────────
  bool isLoading          = false;
  bool obscurePassword    = true;
  bool obscureConfirm     = true;
  bool acceptTerms        = false;
  bool isLoggedIn         = false;
  bool isInitialized      = false;
  AuthMode mode           = AuthMode.login;

  // ── Validation errors ─────────────────────────────────────────────────────
  String? emailError;
  String? passwordError;
  String? nameError;
  String? confirmError;
  String? generalError;

  // ── Mode toggle ───────────────────────────────────────────────────────────
  void toggleMode() {
    mode = mode == AuthMode.login ? AuthMode.signup : AuthMode.login;
    resetErrors();
    notifyListeners();
  }

  // ── Visibility toggles ────────────────────────────────────────────────────
  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmVisibility() {
    obscureConfirm = !obscureConfirm;
    notifyListeners();
  }

  void setAcceptTerms(bool value) {
    acceptTerms = value;
    notifyListeners();
  }

  // ── Field setters ─────────────────────────────────────────────────────────
  void setName(String v) {
    name = v;
    if (nameError != null) {
      nameError = null;
      notifyListeners();
    }
  }

  void setEmail(String v) {
    email = v;
    if (emailError != null) {
      emailError = null;
      notifyListeners();
    }
  }

  void setPassword(String v) {
    password = v;
    if (passwordError != null) {
      passwordError = null;
    }
    notifyListeners();
  }

  void setConfirmPassword(String v) {
    confirmPassword = v;
    if (confirmError != null) {
      confirmError = null;
      notifyListeners();
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────
  bool validateEmail() {
    final regex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (email.isEmpty) {
      emailError = 'E-posta adresi gerekli';
      notifyListeners();
      return false;
    }
    if (!regex.hasMatch(email)) {
      emailError = 'Geçerli bir e-posta adresi girin';
      notifyListeners();
      return false;
    }
    emailError = null;
    notifyListeners();
    return true;
  }

  bool validatePassword() {
    if (password.isEmpty) {
      passwordError = 'Şifre gerekli';
      notifyListeners();
      return false;
    }
    if (password.length < 8) {
      passwordError = 'Şifre en az 8 karakter olmalı';
      notifyListeners();
      return false;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      passwordError = 'Şifre en az 1 rakam içermeli';
      notifyListeners();
      return false;
    }
    passwordError = null;
    notifyListeners();
    return true;
  }

  bool _validateName() {
    if (name.trim().isEmpty) {
      nameError = 'Ad Soyad gerekli';
      notifyListeners();
      return false;
    }
    if (name.trim().split(' ').length < 2) {
      nameError = 'Ad ve soyadınızı girin';
      notifyListeners();
      return false;
    }
    nameError = null;
    notifyListeners();
    return true;
  }

  bool _validateConfirm() {
    if (confirmPassword.isEmpty) {
      confirmError = 'Şifre tekrarı gerekli';
      notifyListeners();
      return false;
    }
    if (confirmPassword != password) {
      confirmError = 'Şifreler eşleşmiyor';
      notifyListeners();
      return false;
    }
    confirmError = null;
    notifyListeners();
    return true;
  }

  // ── Password strength ─────────────────────────────────────────────────────
  PasswordStrength getPasswordStrength() {
    if (password.length < 6) return PasswordStrength.weak;
    int score = 0;
    if (password.length >= 8)  score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  // ── Auto-login: Önceki oturumu kontrol et ────────────────────────────────
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    if (loggedIn) {
      email = prefs.getString(_keyEmail) ?? '';
      name = prefs.getString(_keyName) ?? '';
      isLoggedIn = true;
    }
    isInitialized = true;
    notifyListeners();
    return loggedIn;
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyName, name);
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> submit() async {
    resetErrors();

    bool valid = true;
    if (mode == AuthMode.signup && !_validateName()) valid = false;
    if (!validateEmail()) valid = false;
    if (!validatePassword()) valid = false;
    if (mode == AuthMode.signup && !_validateConfirm()) valid = false;
    if (mode == AuthMode.signup && !acceptTerms) {
      generalError = 'Kullanım koşullarını kabul etmeniz gerekiyor';
      notifyListeners();
      valid = false;
    }
    if (!valid) return;

    isLoading = true;
    notifyListeners();

    // TODO: Gerçek backend entegrasyonu (Firebase/Supabase)
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    isLoading  = false;
    isLoggedIn = true;
    await _persistSession();
    notifyListeners();
  }

  // ── Guest login ───────────────────────────────────────────────────────────
  Future<void> loginAsGuest() async {
    isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 800));

    name  = 'Misafir';
    email = 'guest@tusasistani.app';
    isLoading  = false;
    isLoggedIn = true;
    await _persistSession();
    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
    isLoggedIn = false;
    isInitialized = true;
    email = '';
    name = '';
    password = '';
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void resetErrors() {
    emailError    = null;
    passwordError = null;
    nameError     = null;
    confirmError  = null;
    generalError  = null;
    notifyListeners();
  }
}
