import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Merkezi Firebase Authentication servisi.
/// Google, Apple ve anonim giris destekler.
/// Singleton pattern — Provider ile enjekte edilir.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream & Getters ────────────────────────────────────────────────────

  /// Auth durumu degistikce tetiklenir (login/logout).
  /// AuthWrapper bu stream'i dinler.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Su anki kullanici (null = giris yapilmamis).
  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  // ── Google Sign-In ──────────────────────────────────────────────────────

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        throw const FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Google girisi iptal edildi.',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _createUserInDbIfNotExists(userCredential.user);
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google girisi basarisiz: $e',
      );
    }
  }

  // ── Apple Sign-In ───────────────────────────────────────────────────────

  Future<UserCredential> signInWithApple() async {
    try {
      // Apple icin nonce olustur (guvenlik)
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple ilk giriste isim verir, sonraki girislerde vermez — kaydet
      final user = userCredential.user;
      if (user != null && (user.displayName == null || user.displayName!.isEmpty)) {
        final givenName = appleCredential.givenName ?? '';
        final familyName = appleCredential.familyName ?? '';
        final fullName = '$givenName $familyName'.trim();
        if (fullName.isNotEmpty) {
          await user.updateDisplayName(fullName);
          await user.reload();
        }
      }

      await _createUserInDbIfNotExists(userCredential.user);
      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-failed',
        message: 'Apple girisi basarisiz: ${e.message}',
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-failed',
        message: 'Apple girisi basarisiz: $e',
      );
    }
  }

  // ── Email/Password Sign-In ─────────────────────────────────────────────

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _createUserInDbIfNotExists(userCredential.user);
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ── Email/Password Sign-Up ─────────────────────────────────────────────

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      await _createUserInDbIfNotExists(userCredential.user);
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // ── Firebase hata mesajlarini Turkceye cevir ──────────────────────────

  FirebaseAuthException _mapFirebaseError(dynamic e) {
    if (e is FirebaseAuthException) return e;

    String code = 'unknown';
    String message = 'Bilinmeyen bir hata olustu.';

    final errorStr = e.toString();
    if (errorStr.contains('user-not-found')) {
      code = 'user-not-found';
      message = 'Bu e-posta adresiyle kayitli bir hesap bulunamadi.';
    } else if (errorStr.contains('wrong-password') || errorStr.contains('invalid-credential')) {
      code = 'wrong-password';
      message = 'E-posta veya sifre hatali.';
    } else if (errorStr.contains('email-already-in-use')) {
      code = 'email-already-in-use';
      message = 'Bu e-posta adresi zaten kullanimda.';
    } else if (errorStr.contains('weak-password')) {
      code = 'weak-password';
      message = 'Sifre cok zayif. En az 6 karakter olmali.';
    } else if (errorStr.contains('invalid-email')) {
      code = 'invalid-email';
      message = 'Gecersiz e-posta adresi.';
    } else if (errorStr.contains('too-many-requests')) {
      code = 'too-many-requests';
      message = 'Cok fazla deneme yapildi. Lutfen biraz bekleyin.';
    } else if (errorStr.contains('network-request-failed')) {
      code = 'network-error';
      message = 'Internet baglantinizi kontrol edin.';
    }

    return FirebaseAuthException(code: code, message: message);
  }

  // ── Sign Out ────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ── Firestore: Kullanici kaydi ──────────────────────────────────────────

  /// Ilk giriste kullanici bilgilerini Firestore'a yazar.
  /// Zaten varsa dokunmaz (merge).
  Future<void> _createUserInDbIfNotExists(User? user) async {
    if (user == null) return;

    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'provider': user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'unknown',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Mevcut kullanici — sadece son giris zamanini guncelle
      await docRef.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Apple Sign-In icin guvenlik yardimcilari ────────────────────────────

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// Firebase Auth'un kendi exception sinifi yetersizse kullanilir.
class FirebaseAuthException implements Exception {
  final String code;
  final String message;
  const FirebaseAuthException({required this.code, required this.message});
  @override
  String toString() => 'FirebaseAuthException($code): $message';
}
