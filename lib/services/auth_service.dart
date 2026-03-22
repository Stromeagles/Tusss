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
        throw FirebaseAuthException(
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
