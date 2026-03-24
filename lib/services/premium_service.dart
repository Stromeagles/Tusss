import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Freemium iş modeli servisi — gerçek In-App Purchase desteğiyle.
///
/// Ürün ID'leri:
///   - [kProductMonthly]  → aylık abonelik
///   - [kProductYearly]   → yıllık abonelik
///
/// Web platformunda IAP devre dışıdır; premium durumu SharedPreferences'tan okunur.
class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  // ── Ürün ID'leri ──────────────────────────────────────────────────────────
  static const String kProductMonthly = 'tus_premium_monthly';
  static const String kProductYearly  = 'tus_premium_yearly';
  static const Set<String> _productIds = {kProductMonthly, kProductYearly};

  // ── Sabitler ──────────────────────────────────────────────────────────────
  static const int dailyFreeFlashcardLimit = 20;
  static const int dailyFreeCaseLimit      = 20;

  /// Reviewer / admin hesapları — her zaman premium.
  static const Set<String> _reviewerEmails = {
    'reviewer@tusasistani.app',
    'ceylannurettin@outlook.com',
  };

  // ── SharedPreferences anahtarları ─────────────────────────────────────────
  static const String _keyIsPremium            = 'is_premium';
  static const String _keyTodayFlashcardCount  = 'today_flashcard_count';
  static const String _keyTodayCaseCount       = 'today_case_count';
  static const String _keyLastLimitDate        = 'last_limit_date';

  // ── IAP dahili durum ──────────────────────────────────────────────────────
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];
  bool _iapAvailable = false;
  bool _loading = false;

  /// Satın alma akışını takip eden stream (UI için dinlenebilir).
  final StreamController<PurchaseStatus?> purchaseStatusStream =
      StreamController<PurchaseStatus?>.broadcast();

  // ── Başlatma ──────────────────────────────────────────────────────────────

  /// Uygulama başlangıcında çağır.
  /// Web'de sessizce çıkar.
  Future<void> init() async {
    if (kIsWeb) return;

    _iapAvailable = await _iap.isAvailable();
    if (!_iapAvailable) return;

    // Satın alma stream'ini dinle
    _purchaseSubscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {},
    );

    // Mevcut satın almaları geri yükle (uygulama yeniden açılınca)
    await _restoreAndVerify();
  }

  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    await purchaseStatusStream.close();
  }

  // ── Ürün Yükleme ──────────────────────────────────────────────────────────

  /// Mağaza ürünlerini yükler. Paywall göstermeden önce çağır.
  Future<List<ProductDetails>> loadProducts() async {
    if (kIsWeb || !_iapAvailable) return [];
    if (_products.isNotEmpty) return _products;

    final response = await _iap.queryProductDetails(_productIds);
    _products = response.productDetails;
    return _products;
  }

  // ── Satın Alma ────────────────────────────────────────────────────────────

  /// Belirtilen ürünü satın al.
  /// [productId]: [kProductMonthly] veya [kProductYearly].
  Future<bool> buyPremium(String productId) async {
    if (kIsWeb || !_iapAvailable) return false;
    if (_loading) return false;

    if (_products.isEmpty) await loadProducts();
    final product = _products.cast<ProductDetails?>().firstWhere(
      (p) => p?.id == productId,
      orElse: () => null,
    );
    if (product == null) return false;

    _loading = true;
    final param = PurchaseParam(productDetails: product);

    try {
      // Abonelik satın alma
      await _iap.buyNonConsumable(purchaseParam: param);
      return true;
    } catch (_) {
      _loading = false;
      return false;
    }
  }

  /// Önceki satın almaları geri yükle (cihaz değişimi veya yeniden kurulum).
  Future<void> restorePurchases() async {
    if (kIsWeb || !_iapAvailable) return;
    await _iap.restorePurchases();
  }

  // ── Satın Alma Güncellemeleri ─────────────────────────────────────────────

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        purchaseStatusStream.add(PurchaseStatus.pending);
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        _loading = false;
        purchaseStatusStream.add(PurchaseStatus.error);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Sunucu tarafı doğrulama burada yapılabilir.
        // Şimdilik doğrudan aktif ediyoruz.
        await _activatePremium();
        _loading = false;
        purchaseStatusStream.add(purchase.status);

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }

      if (purchase.status == PurchaseStatus.canceled) {
        _loading = false;
        purchaseStatusStream.add(PurchaseStatus.canceled);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _restoreAndVerify() async {
    if (!_iapAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  // ── Premium Aktivasyon ────────────────────────────────────────────────────

  Future<void> _activatePremium() async {
    await setPremium(true);

    // Firestore'a da yaz — diğer cihazlarda senkronize olsun.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'isPremium': true, 'premiumActivatedAt': FieldValue.serverTimestamp()},
              SetOptions(merge: true))
          .catchError((_) {});
    }
  }

  // ── Premium Durum ─────────────────────────────────────────────────────────

  Future<bool> isPremium() async {
    // Reviewer hesapları her zaman premium
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (email != null && _reviewerEmails.contains(email)) return true;

    // Firestore'dan kontrol et (en yetkili kaynak)
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 4));
        final remote = doc.data()?['isPremium'] as bool? ?? false;
        if (remote) {
          // Yerel cache'i güncelle
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_keyIsPremium, true);
          return true;
        }
      } catch (_) {}
    }

    // Yerel cache'e düş
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPremium) ?? false;
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, value);
  }

  // ── Günlük Sayaçlar ───────────────────────────────────────────────────────

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _resetIfNewDay(SharedPreferences prefs) async {
    final today = _todayStr();
    final lastDate = prefs.getString(_keyLastLimitDate) ?? '';
    if (lastDate != today) {
      await prefs.setInt(_keyTodayFlashcardCount, 0);
      await prefs.setInt(_keyTodayCaseCount, 0);
      await prefs.setString(_keyLastLimitDate, today);
    }
  }

  Future<int> getTodayFlashcardCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    return prefs.getInt(_keyTodayFlashcardCount) ?? 0;
  }

  Future<int> getTodayCaseCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    return prefs.getInt(_keyTodayCaseCount) ?? 0;
  }

  Future<void> incrementFlashcard() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final current = prefs.getInt(_keyTodayFlashcardCount) ?? 0;
    await prefs.setInt(_keyTodayFlashcardCount, current + 1);
  }

  Future<void> incrementCase() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final current = prefs.getInt(_keyTodayCaseCount) ?? 0;
    await prefs.setInt(_keyTodayCaseCount, current + 1);
  }

  Future<bool> isFlashcardLimitReached() async {
    if (await isPremium()) return false;
    return await getTodayFlashcardCount() >= dailyFreeFlashcardLimit;
  }

  Future<bool> isCaseLimitReached() async {
    if (await isPremium()) return false;
    return await getTodayCaseCount() >= dailyFreeCaseLimit;
  }

  Future<int> remainingFlashcards() async {
    if (await isPremium()) return 999;
    final count = await getTodayFlashcardCount();
    return (dailyFreeFlashcardLimit - count).clamp(0, dailyFreeFlashcardLimit);
  }

  Future<int> remainingCases() async {
    if (await isPremium()) return 999;
    final count = await getTodayCaseCount();
    return (dailyFreeCaseLimit - count).clamp(0, dailyFreeCaseLimit);
  }
}
