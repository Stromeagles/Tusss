import 'package:flutter/foundation.dart';

enum AuthMode { login, signup }

enum PasswordStrength { weak, medium, strong }

class AuthViewModel extends ChangeNotifier {
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

    // Mock network delay
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    isLoading  = false;
    isLoggedIn = true;
    notifyListeners();
  }

  // ── Guest login ───────────────────────────────────────────────────────────
  Future<void> loginAsGuest() async {
    isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 800));

    isLoading  = false;
    isLoggedIn = true;
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
