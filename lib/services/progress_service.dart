import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_model.dart';

class ProgressService {
  static const String _keyFlashcardsStudied = 'flashcards_studied';
  static const String _keyCasesAttempted = 'cases_attempted';
  static const String _keyCorrectAnswers = 'correct_answers';
  static const String _keyCompletedCards = 'completed_cards';
  static const String _keyDailyGoal = 'daily_goal';
  static const String _keyTodayStudied = 'today_studied';
  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyLongestStreak = 'longest_streak';
  static const String _keyLastStudyDate = 'last_study_date';
  static const String _keyWeeklyStats = 'weekly_stats';

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<StudyProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final completedJson = prefs.getString(_keyCompletedCards);
    Map<String, bool> completed = {};
    if (completedJson != null) {
      final decoded = json.decode(completedJson) as Map<String, dynamic>;
      completed = decoded.map((k, v) => MapEntry(k, v as bool));
    }

    final weeklyJson = prefs.getString(_keyWeeklyStats);
    Map<String, int> weekly = {};
    if (weeklyJson != null) {
      final decoded = json.decode(weeklyJson) as Map<String, dynamic>;
      weekly = decoded.map((k, v) => MapEntry(k, v as int));
    }

    // Eğer son çalışma günü bugün değilse todayStudied sıfırla
    final lastDate = prefs.getString(_keyLastStudyDate) ?? '';
    final today = _todayStr();
    int todayStudied = prefs.getInt(_keyTodayStudied) ?? 0;
    if (lastDate != today && lastDate.isNotEmpty) {
      todayStudied = 0;
    }

    return StudyProgress(
      totalFlashcardsStudied: prefs.getInt(_keyFlashcardsStudied) ?? 0,
      totalCasesAttempted: prefs.getInt(_keyCasesAttempted) ?? 0,
      correctAnswers: prefs.getInt(_keyCorrectAnswers) ?? 0,
      completedFlashcards: completed,
      dailyGoal: prefs.getInt(_keyDailyGoal) ?? 50,
      todayStudied: todayStudied,
      currentStreak: prefs.getInt(_keyCurrentStreak) ?? 0,
      longestStreak: prefs.getInt(_keyLongestStreak) ?? 0,
      lastStudyDate: lastDate,
      weeklyStats: weekly,
    );
  }

  Future<void> markFlashcardSeen(String id) async {
    final prefs = await SharedPreferences.getInstance();

    final completedJson = prefs.getString(_keyCompletedCards);
    Map<String, bool> completed = {};
    if (completedJson != null) {
      final decoded = json.decode(completedJson) as Map<String, dynamic>;
      completed = decoded.map((k, v) => MapEntry(k, v as bool));
    }

    if (!completed.containsKey(id)) {
      completed[id] = true;
      await prefs.setString(_keyCompletedCards, json.encode(completed));
      final current = prefs.getInt(_keyFlashcardsStudied) ?? 0;
      await prefs.setInt(_keyFlashcardsStudied, current + 1);

      // Bugünkü çalışma sayısını güncelle
      final today = _todayStr();
      final lastDate = prefs.getString(_keyLastStudyDate) ?? '';
      int todayStudied = prefs.getInt(_keyTodayStudied) ?? 0;

      if (lastDate != today) {
        todayStudied = 0; // Yeni gün, sıfırla
      }
      todayStudied++;
      await prefs.setInt(_keyTodayStudied, todayStudied);

      // Streak hesapla
      int streak = prefs.getInt(_keyCurrentStreak) ?? 0;
      int longest = prefs.getInt(_keyLongestStreak) ?? 0;

      if (lastDate.isEmpty) {
        streak = 1;
      } else if (lastDate == today) {
        // Zaten bugün çalışıldı, streak değişmez
      } else {
        final last = DateTime.parse(lastDate);
        final diff = DateTime.now().difference(last).inDays;
        if (diff == 1) {
          streak++;
        } else {
          streak = 1;
        }
      }

      if (streak > longest) longest = streak;
      await prefs.setInt(_keyCurrentStreak, streak);
      await prefs.setInt(_keyLongestStreak, longest);
      await prefs.setString(_keyLastStudyDate, today);

      // Haftalık istatistik
      final weeklyJson = prefs.getString(_keyWeeklyStats);
      Map<String, int> weekly = {};
      if (weeklyJson != null) {
        final decoded = json.decode(weeklyJson) as Map<String, dynamic>;
        weekly = decoded.map((k, v) => MapEntry(k, v as int));
      }
      weekly[today] = (weekly[today] ?? 0) + 1;
      // 14 günden eski verileri temizle
      final cutoff = DateTime.now().subtract(const Duration(days: 14));
      weekly.removeWhere((k, _) => DateTime.parse(k).isBefore(cutoff));
      await prefs.setString(_keyWeeklyStats, json.encode(weekly));
    }
  }

  Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyGoal, goal);
  }

  Future<void> recordCaseAnswer({required bool correct}) async {
    final prefs = await SharedPreferences.getInstance();
    final attempted = (prefs.getInt(_keyCasesAttempted) ?? 0) + 1;
    await prefs.setInt(_keyCasesAttempted, attempted);
    if (correct) {
      final correctCount = (prefs.getInt(_keyCorrectAnswers) ?? 0) + 1;
      await prefs.setInt(_keyCorrectAnswers, correctCount);
    }
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFlashcardsStudied);
    await prefs.remove(_keyCasesAttempted);
    await prefs.remove(_keyCorrectAnswers);
    await prefs.remove(_keyCompletedCards);
    await prefs.remove(_keyDailyGoal);
    await prefs.remove(_keyTodayStudied);
    await prefs.remove(_keyCurrentStreak);
    await prefs.remove(_keyLongestStreak);
    await prefs.remove(_keyLastStudyDate);
    await prefs.remove(_keyWeeklyStats);
  }
}
