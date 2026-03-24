import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sm2_model.dart';
import 'auth_service.dart';

class SpacedRepetitionService {
  static final SpacedRepetitionService _instance =
      SpacedRepetitionService._internal();
  factory SpacedRepetitionService() => _instance;
  SpacedRepetitionService._internal();

  static const String _prefsKey = 'sm2_card_data';

  Map<String, SM2CardData>? _cache;

  // ── Firestore yolu ────────────────────────────────────────────────────────
  DocumentReference? get _firestoreDoc {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('content')
        .doc('srs_data');
  }

  // ── Firestore'a asenkron yedekle ─────────────────────────────────────────
  void _backupToFirestore(Map<String, SM2CardData> data) {
    final doc = _firestoreDoc;
    if (doc == null) return;
    final encoded = data.map((k, v) => MapEntry(k, v.toJson()));
    doc.set({
      'sm2_card_data': encoded,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((_) {});
  }

  // ── Veri yükleme: Firestore → SharedPreferences → cache ──────────────────
  Future<Map<String, SM2CardData>> getAllData() async {
    if (_cache != null) return _cache!;

    final prefs = await SharedPreferences.getInstance();

    // Firestore'dan senkronize et (giriş yapılmışsa)
    final doc = _firestoreDoc;
    if (doc != null) {
      try {
        final snap = await doc.get().timeout(const Duration(seconds: 6));
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          final remoteCards = data['sm2_card_data'] as Map<String, dynamic>?;
          if (remoteCards != null && remoteCards.isNotEmpty) {
            // Firestore verisi varsa yereli güncelle
            final encoded = json.encode(remoteCards);
            await prefs.setString(_prefsKey, encoded);
          }
        }
      } catch (_) {
        // Firestore erişilemiyorsa yerel veriye düş
      }
    }

    // Yerelden yükle
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      _cache = {};
      return _cache!;
    }
    final decoded = json.decode(raw) as Map<String, dynamic>;
    _cache = decoded.map(
      (k, v) => MapEntry(k, SM2CardData.fromJson(v as Map<String, dynamic>)),
    );
    return _cache!;
  }

  Future<void> _saveAll(Map<String, SM2CardData> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(data.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString(_prefsKey, encoded);
    _cache = data;
    _backupToFirestore(data);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<SM2CardData> getCardData(String cardId) async {
    final all = await getAllData();
    return all[cardId] ?? SM2CardData.initial(cardId);
  }

  Future<SM2CardData> recordAnswer(String cardId, int quality) async {
    final all = await getAllData();
    final current = all[cardId] ?? SM2CardData.initial(cardId);
    final updated = current.computeNext(quality);
    all[cardId] = updated;
    await _saveAll(all);
    return updated;
  }

  Future<List<String>> getDueCardIds() async {
    final all = await getAllData();
    return all.entries
        .where((e) => e.value.isDue)
        .map((e) => e.key)
        .toList();
  }

  Future<List<String>> filterDueCards(List<String> cardIds) async {
    final all = await getAllData();
    return cardIds.where((id) {
      final data = all[id];
      if (data == null) return true;
      return data.isDue;
    }).toList();
  }

  Future<String> getNextReviewLabel(String cardId) async {
    final data = await getCardData(cardId);
    if (data.repetitions == 0) return 'Yeni kart';
    final diff = data.nextReviewDate.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Bugün tekrar';
    if (diff == 1) return 'Yarın tekrar';
    return '$diff gün sonra';
  }

  Future<SM2CardData> toggleBookmark(String cardId) async {
    final all = await getAllData();
    final current = all[cardId] ?? SM2CardData.initial(cardId);
    final updated = current.copyWithBookmark(!current.isBookmarked);
    all[cardId] = updated;
    await _saveAll(all);
    return updated;
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _cache = null;
    _firestoreDoc?.delete().catchError((_) {});
  }

  void clearCache() {
    _cache = null;
  }

  /// Giriş yapıldığında cache'i temizle — getAllData yeniden Firestore'dan çeksin
  void onUserLogin() {
    _cache = null;
  }

  Future<SrsSummary> getSummary(List<String> allIds, {int? dailyGoal}) async {
    final all = await getAllData();
    int newCount      = 0;
    int toReviewCount = 0;
    int learnedCount  = 0;
    int bookmarkCount = 0;

    for (final id in allIds) {
      final data = all[id];
      if (data == null) {
        newCount++;
      } else {
        if (data.isBookmarked) bookmarkCount++;
        if (data.lastQuality == 1) {
          toReviewCount++;
        } else if (data.lastQuality == 2) {
          learnedCount++;
        } else if (data.repetitions == 0) {
          newCount++;
        }
      }
    }
    if (dailyGoal != null && dailyGoal > 0 && newCount > dailyGoal) {
      newCount = dailyGoal;
    }
    return SrsSummary(
      newCount:      newCount,
      toReviewCount: toReviewCount,
      learnedCount:  learnedCount,
      bookmarkCount: bookmarkCount,
    );
  }
}

class SrsSummary {
  final int newCount;
  final int toReviewCount;
  final int learnedCount;
  final int bookmarkCount;

  const SrsSummary({
    required this.newCount,
    required this.toReviewCount,
    required this.learnedCount,
    required this.bookmarkCount,
  });

  int get activeCount => newCount + toReviewCount + learnedCount;
  int get cardCount   => newCount + toReviewCount + learnedCount + bookmarkCount;
}
