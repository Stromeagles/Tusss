import 'package:shared_preferences/shared_preferences.dart';

/// Freemium iş modeli servisi.
/// Ücretsiz kullanıcılar günlük 50 flashcard + 50 soru limiti ile sınırlıdır.
/// Premium kullanıcılar için tüm limitler kaldırılır.
class PremiumService {
  // Singleton
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  static const int dailyFreeFlashcardLimit = 50;
  static const int dailyFreeCaseLimit = 50;

  static const String _keyIsPremium = 'is_premium';
  static const String _keyTodayFlashcardCount = 'today_flashcard_count';
  static const String _keyTodayCaseCount = 'today_case_count';
  static const String _keyLastLimitDate = 'last_limit_date';

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ── Premium Durum ─────────────────────────────────────────────────────────

  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPremium) ?? false;
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, value);
  }

  // ── Günlük Sayaçlar ──────────────────────────────────────────────────────

  Future<void> _resetIfNewDay(SharedPreferences prefs) async {
    final today = _todayStr();
    final lastDate = prefs.getString(_keyLastLimitDate) ?? '';
    if (lastDate != today) {
      await prefs.setInt(_keyTodayFlashcardCount, 0);
      await prefs.setInt(_keyTodayCaseCount, 0);
      await prefs.setString(_keyLastLimitDate, today);
    }
  }

  /// Bugün kullanılan flashcard sayısını döndürür.
  Future<int> getTodayFlashcardCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    return prefs.getInt(_keyTodayFlashcardCount) ?? 0;
  }

  /// Bugün kullanılan soru sayısını döndürür.
  Future<int> getTodayCaseCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    return prefs.getInt(_keyTodayCaseCount) ?? 0;
  }

  /// Flashcard sayacını 1 artırır.
  Future<void> incrementFlashcard() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final current = prefs.getInt(_keyTodayFlashcardCount) ?? 0;
    await prefs.setInt(_keyTodayFlashcardCount, current + 1);
  }

  /// Soru sayacını 1 artırır.
  Future<void> incrementCase() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final current = prefs.getInt(_keyTodayCaseCount) ?? 0;
    await prefs.setInt(_keyTodayCaseCount, current + 1);
  }

  /// Flashcard limiti aşıldı mı?
  Future<bool> isFlashcardLimitReached() async {
    if (await isPremium()) return false;
    final count = await getTodayFlashcardCount();
    return count >= dailyFreeFlashcardLimit;
  }

  /// Soru limiti aşıldı mı?
  Future<bool> isCaseLimitReached() async {
    if (await isPremium()) return false;
    final count = await getTodayCaseCount();
    return count >= dailyFreeCaseLimit;
  }

  /// Kalan flashcard hakkı
  Future<int> remainingFlashcards() async {
    if (await isPremium()) return 999;
    final count = await getTodayFlashcardCount();
    return (dailyFreeFlashcardLimit - count).clamp(0, dailyFreeFlashcardLimit);
  }

  /// Kalan soru hakkı
  Future<int> remainingCases() async {
    if (await isPremium()) return 999;
    final count = await getTodayCaseCount();
    return (dailyFreeCaseLimit - count).clamp(0, dailyFreeCaseLimit);
  }
}
