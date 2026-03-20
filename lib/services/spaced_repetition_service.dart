import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sm2_model.dart';

class SpacedRepetitionService {
  static final SpacedRepetitionService _instance =
      SpacedRepetitionService._internal();
  factory SpacedRepetitionService() => _instance;
  SpacedRepetitionService._internal();

  static const String _prefsKey = 'sm2_card_data';

  Map<String, SM2CardData>? _cache;

  // ── Veri yükleme ──────────────────────────────────────────────────────────

  Future<Map<String, SM2CardData>> getAllData() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
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
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Bir kartın SM-2 verisini getirir; yoksa yeni kart olarak başlatır.
  Future<SM2CardData> getCardData(String cardId) async {
    final all = await getAllData();
    return all[cardId] ?? SM2CardData.initial(cardId);
  }

  /// Kullanıcı yanıtını işle ve kartı güncelle.
  /// quality: 1 = Bilemedim (1 gün), 2 = Bildim (3 gün)
  Future<SM2CardData> recordAnswer(String cardId, int quality) async {
    final all = await getAllData();
    final current = all[cardId] ?? SM2CardData.initial(cardId);
    final updated = current.computeNext(quality);
    all[cardId] = updated;
    await _saveAll(all);
    return updated;
  }

  /// Bugün tekrar edilmesi gereken kart ID'lerini döner.
  Future<List<String>> getDueCardIds() async {
    final all = await getAllData();
    return all.entries
        .where((e) => e.value.isDue)
        .map((e) => e.key)
        .toList();
  }

  /// Verilen kart listesinden sadece bugün zamanı gelenleri filtreler.
  Future<List<String>> filterDueCards(List<String> cardIds) async {
    final all = await getAllData();
    return cardIds.where((id) {
      final data = all[id];
      if (data == null) return true; // yeni kart → hemen göster
      return data.isDue;
    }).toList();
  }

  /// Bir kartın bir sonraki tekrar tarihini insan-okunur formatta döner.
  Future<String> getNextReviewLabel(String cardId) async {
    final data = await getCardData(cardId);
    if (data.repetitions == 0) return 'Yeni kart';
    final diff = data.nextReviewDate.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Bugün tekrar';
    if (diff == 1) return 'Yarın tekrar';
    return '$diff gün sonra';
  }

  /// Bookmark toggle — isBookmarked alanını değiştirir.
  Future<SM2CardData> toggleBookmark(String cardId) async {
    final all = await getAllData();
    final current = all[cardId] ?? SM2CardData.initial(cardId);
    final updated = current.copyWithBookmark(!current.isBookmarked);
    all[cardId] = updated;
    await _saveAll(all);
    return updated;
  }

  /// Tüm verileri sıfırla.
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _cache = null;
  }

  void clearCache() {
    _cache = null;
  }

  /// Bilemediklerim / Bildiklerim / Ezberim / Yeni sayılarını döner — home screen için
  Future<SrsSummary> getSummary(List<String> allIds, {int? dailyGoal}) async {
    final all = await getAllData();
    int newCount      = 0;
    int toReviewCount = 0; // lastQuality == 1 (Bilemediklerim)
    int learnedCount  = 0; // lastQuality == 2 (Bildiklerim)
    int bookmarkCount = 0; // isBookmarked (Ezberim)

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
  final int toReviewCount; // Bilemediklerim (lastQuality == 1)
  final int learnedCount;  // Bildiklerim (lastQuality == 2)
  final int bookmarkCount; // Ezberim (isBookmarked)

  const SrsSummary({
    required this.newCount,
    required this.toReviewCount,
    required this.learnedCount,
    required this.bookmarkCount,
  });

  int get activeCount => newCount + toReviewCount + learnedCount;
  int get cardCount => newCount + toReviewCount + learnedCount + bookmarkCount;
}
