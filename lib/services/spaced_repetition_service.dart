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
  /// quality: 0-5 (sağ kaydır = 4 "Bildim", sol kaydır = 1 "Bilmedim")
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
  /// Hiç görülmemiş kartlar da "due" sayılır.
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
    if (data.isInPocket) return '🧠 Hafıza! (3 gün sonra)';
    final diff = data.nextReviewDate
        .difference(DateTime.now())
        .inDays;
    if (diff <= 0) return 'Bugün tekrar';
    if (diff == 1) return 'Yarın tekrar';
    return '$diff gün sonra';
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

  /// New/Due/Pocket sayılarını döner — home screen için
  Future<SrsSummary> getSummary(List<String> allIds, {int? dailyGoal}) async {
    final all = await getAllData();
    int newCount      = 0;
    int failedCount   = 0; // görülmüş, repetitions == 0 (Tekrar'a düşmüş)
    int learningCount = 0; // repetitions >= 1, cepte değil
    int pocketCount   = 0;

    for (final id in allIds) {
      final data = all[id];
      if (data == null) {
        newCount++;                           // hiç görülmemiş
      } else if (data.isInPocket) {
        pocketCount++;                        // Hafıza'da
      } else if (data.repetitions == 0) {
        failedCount++;                        // görülmüş ama sıfırlanmış
      } else {
        learningCount++;                      // repetitions >= 1 (öğrenme / pekiştirme)
      }
    }
    if (dailyGoal != null && dailyGoal > 0 && newCount > dailyGoal) newCount = dailyGoal;
    return SrsSummary(
      newCount:      newCount,
      failedCount:   failedCount,
      learningCount: learningCount,
      pocketCount:   pocketCount,
    );
  }
}

class SrsSummary {
  final int newCount;
  final int failedCount;    // Görülmüş ama repetitions == 0 (Tekrar'a düşmüş)
  final int learningCount;  // "Öğreniyor" — repetitions >= 1, cepte değil
  final int pocketCount;

  const SrsSummary({
    required this.newCount,
    required this.failedCount,
    required this.learningCount,
    required this.pocketCount,
  });

  /// Cards still needing active work (not yet mastered/in pocket).
  int get activeCount => newCount + failedCount + learningCount;

  /// Total cards across all categories.
  int get cardCount => newCount + failedCount + learningCount + pocketCount;
}
