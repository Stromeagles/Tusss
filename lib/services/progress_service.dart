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
  static const String _keyWeekdayGoalHours = 'weekday_goal_hours';
  static const String _keyWeekendGoalHours = 'weekend_goal_hours';
  static const String _keyTargetTusDate = 'target_tus_date';
  static const String _keySelectedSubjects = 'selected_subjects';
  static const String _keyBaseScore = 'base_score';
  static const String _keyTargetScore = 'target_score';
  static const String _keyFocusMinutes = 'focus_minutes';

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
      weekdayGoalHours: prefs.getDouble(_keyWeekdayGoalHours) ?? 2.0,
      weekendGoalHours: prefs.getDouble(_keyWeekendGoalHours) ?? 4.0,
      targetTusDate: prefs.getString(_keyTargetTusDate) ?? '2026-06-28',
      selectedSubjectIds: prefs.getStringList(_keySelectedSubjects) ?? [],
      baseScore: prefs.getDouble(_keyBaseScore) ?? 45.0,
      targetScore: prefs.getDouble(_keyTargetScore) ?? 65.0,
    );
  }

  /// Streak ve günlük çalışma sayacını günceller.
  /// Hem flashcard hem case çalışmasından çağrılır.
  Future<void> _updateDailyActivity(SharedPreferences prefs) async {
    final today = _todayStr();
    final lastDate = prefs.getString(_keyLastStudyDate) ?? '';
    int todayStudied = prefs.getInt(_keyTodayStudied) ?? 0;

    if (lastDate != today) {
      todayStudied = 0;
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
    final today2 = today;
    final weeklyJson = prefs.getString(_keyWeeklyStats);
    Map<String, int> weekly = {};
    if (weeklyJson != null) {
      final decoded = json.decode(weeklyJson) as Map<String, dynamic>;
      weekly = decoded.map((k, v) => MapEntry(k, v as int));
    }
    weekly[today2] = (weekly[today2] ?? 0) + 1;
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    weekly.removeWhere((k, _) => DateTime.parse(k).isBefore(cutoff));
    await prefs.setString(_keyWeeklyStats, json.encode(weekly));
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
      await _updateDailyActivity(prefs);
    }
  }

  Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyGoal, goal);
  }

  Future<void> saveGoalSettings({
    required double weekdayGoalHours,
    required double weekendGoalHours,
    required String targetTusDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyWeekdayGoalHours, weekdayGoalHours);
    await prefs.setDouble(_keyWeekendGoalHours, weekendGoalHours);
    await prefs.setString(_keyTargetTusDate, targetTusDate);
  }

  Future<void> saveScoreGoal({required double base, required double target}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBaseScore, base);
    await prefs.setDouble(_keyTargetScore, target);
  }

  Future<void> recordCaseAnswer({String? caseId, required bool correct}) async {
    final prefs = await SharedPreferences.getInstance();

    final attempted = (prefs.getInt(_keyCasesAttempted) ?? 0) + 1;
    await prefs.setInt(_keyCasesAttempted, attempted);

    if (correct) {
      final correctCount = (prefs.getInt(_keyCorrectAnswers) ?? 0) + 1;
      await prefs.setInt(_keyCorrectAnswers, correctCount);
    }

    // Streak dahil tüm günlük aktiviteyi güncelle
    await _updateDailyActivity(prefs);
  }
  
  Future<void> recordFocusMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyFocusMinutes) ?? 0;
    await prefs.setInt(_keyFocusMinutes, current + minutes);
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
    await prefs.remove(_keyWeekdayGoalHours);
    await prefs.remove(_keyWeekendGoalHours);
    await prefs.remove(_keyTargetTusDate);
    await prefs.remove(_keyBaseScore);
    await prefs.remove(_keyTargetScore);
  }
}
