import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_model.dart';
import 'auth_service.dart';

class ProgressService {
  static const String _keyFlashcardsStudied = 'flashcards_studied';
  static const String _keyCasesAttempted    = 'cases_attempted';
  static const String _keyCorrectAnswers    = 'correct_answers';
  static const String _keyCompletedCards    = 'completed_cards';
  static const String _keyDailyGoal         = 'daily_goal';
  static const String _keyTodayStudied      = 'today_studied';
  static const String _keyCurrentStreak     = 'current_streak';
  static const String _keyLongestStreak     = 'longest_streak';
  static const String _keyLastStudyDate     = 'last_study_date';
  static const String _keyWeeklyStats       = 'weekly_stats';
  static const String _keyWeekdayGoalHours  = 'weekday_goal_hours';
  static const String _keyWeekendGoalHours  = 'weekend_goal_hours';
  static const String _keyTargetTusDate     = 'target_tus_date';
  static const String _keySelectedSubjects  = 'selected_subjects';
  static const String _keyBaseScore         = 'base_score';
  static const String _keyTargetScore       = 'target_score';
  static const String _keyFocusMinutes      = 'focus_minutes';

  // ── Firestore yolu ────────────────────────────────────────────────────────
  DocumentReference? get _firestoreDoc {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('content')
        .doc('study_data');
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  // ── Yükleme: önce Firestore, sonra yereli güncelle ────────────────────────
  Future<StudyProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // Giriş yapılmışsa Firestore'dan senkronize et
    final doc = _firestoreDoc;
    if (doc != null) {
      try {
        final snap = await doc.get().timeout(const Duration(seconds: 6));
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          await _mergeFirestoreToPrefs(prefs, data);
        }
      } catch (_) {
        // Firestore erişilemiyorsa yerel veriye düş
      }
    }

    return _readFromPrefs(prefs);
  }

  /// Firestore verisini SharedPreferences'e yaz (Firestore daha yeniyse)
  Future<void> _mergeFirestoreToPrefs(
      SharedPreferences prefs, Map<String, dynamic> data) async {
    void setIfPresent<T>(String key, T? value) {
      if (value == null) return;
      if (value is int)    prefs.setInt(key, value);
      if (value is double) prefs.setDouble(key, value);
      if (value is String) prefs.setString(key, value);
    }

    setIfPresent(_keyFlashcardsStudied, data['flashcards_studied'] as int?);
    setIfPresent(_keyCasesAttempted,    data['cases_attempted']    as int?);
    setIfPresent(_keyCorrectAnswers,    data['correct_answers']    as int?);
    setIfPresent(_keyDailyGoal,         data['daily_goal']         as int?);
    setIfPresent(_keyTodayStudied,      data['today_studied']      as int?);
    setIfPresent(_keyCurrentStreak,     data['current_streak']     as int?);
    setIfPresent(_keyLongestStreak,     data['longest_streak']     as int?);
    setIfPresent(_keyFocusMinutes,      data['focus_minutes']      as int?);
    setIfPresent(_keyLastStudyDate,     data['last_study_date']    as String?);
    setIfPresent(_keyTargetTusDate,     data['target_tus_date']    as String?);
    setIfPresent(_keyWeekdayGoalHours,  (data['weekday_goal_hours'] as num?)?.toDouble());
    setIfPresent(_keyWeekendGoalHours,  (data['weekend_goal_hours'] as num?)?.toDouble());
    setIfPresent(_keyBaseScore,         (data['base_score']         as num?)?.toDouble());
    setIfPresent(_keyTargetScore,       (data['target_score']       as num?)?.toDouble());

    if (data['completed_cards'] != null) {
      await prefs.setString(_keyCompletedCards, json.encode(data['completed_cards']));
    }
    if (data['weekly_stats'] != null) {
      await prefs.setString(_keyWeeklyStats, json.encode(data['weekly_stats']));
    }
    if (data['selected_subjects'] != null) {
      final list = (data['selected_subjects'] as List).cast<String>();
      await prefs.setStringList(_keySelectedSubjects, list);
    }
  }

  StudyProgress _readFromPrefs(SharedPreferences prefs) {
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

    final lastDate = prefs.getString(_keyLastStudyDate) ?? '';
    final today = _todayStr();
    int todayStudied = prefs.getInt(_keyTodayStudied) ?? 0;
    if (lastDate != today && lastDate.isNotEmpty) todayStudied = 0;

    return StudyProgress(
      totalFlashcardsStudied: prefs.getInt(_keyFlashcardsStudied) ?? 0,
      totalCasesAttempted:    prefs.getInt(_keyCasesAttempted)    ?? 0,
      correctAnswers:         prefs.getInt(_keyCorrectAnswers)    ?? 0,
      completedFlashcards:    completed,
      dailyGoal:              prefs.getInt(_keyDailyGoal)         ?? 20,
      todayStudied:           todayStudied,
      currentStreak:          prefs.getInt(_keyCurrentStreak)     ?? 0,
      longestStreak:          prefs.getInt(_keyLongestStreak)     ?? 0,
      lastStudyDate:          lastDate,
      weeklyStats:            weekly,
      weekdayGoalHours:       prefs.getDouble(_keyWeekdayGoalHours) ?? 2.0,
      weekendGoalHours:       prefs.getDouble(_keyWeekendGoalHours) ?? 4.0,
      targetTusDate:          prefs.getString(_keyTargetTusDate)  ?? '2026-06-28',
      selectedSubjectIds:     prefs.getStringList(_keySelectedSubjects) ?? [],
      baseScore:              prefs.getDouble(_keyBaseScore)      ?? 45.0,
      targetScore:            prefs.getDouble(_keyTargetScore)    ?? 65.0,
    );
  }

  // ── Firestore'a asenkron yedekle ─────────────────────────────────────────
  void _backupToFirestore(Map<String, dynamic> data) {
    final doc = _firestoreDoc;
    if (doc == null) return;
    doc.set(data, SetOptions(merge: true)).catchError((_) {});
  }

  // ── Günlük aktivite ───────────────────────────────────────────────────────
  Future<void> _updateDailyActivity(SharedPreferences prefs) async {
    final today = _todayStr();
    final lastDate = prefs.getString(_keyLastStudyDate) ?? '';
    int todayStudied = prefs.getInt(_keyTodayStudied) ?? 0;

    if (lastDate != today) todayStudied = 0;
    todayStudied++;
    await prefs.setInt(_keyTodayStudied, todayStudied);

    int streak  = prefs.getInt(_keyCurrentStreak) ?? 0;
    int longest = prefs.getInt(_keyLongestStreak) ?? 0;

    if (lastDate.isEmpty) {
      streak = 1;
    } else if (lastDate != today) {
      final last = DateTime.parse(lastDate);
      final diff = DateTime.now().difference(last).inDays;
      streak = diff == 1 ? streak + 1 : 1;
    }

    if (streak > longest) longest = streak;
    await prefs.setInt(_keyCurrentStreak, streak);
    await prefs.setInt(_keyLongestStreak, longest);
    await prefs.setString(_keyLastStudyDate, today);

    final weeklyJson = prefs.getString(_keyWeeklyStats);
    Map<String, int> weekly = {};
    if (weeklyJson != null) {
      final decoded = json.decode(weeklyJson) as Map<String, dynamic>;
      weekly = decoded.map((k, v) => MapEntry(k, v as int));
    }
    weekly[today] = (weekly[today] ?? 0) + 1;
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    weekly.removeWhere((k, _) => DateTime.parse(k).isBefore(cutoff));
    await prefs.setString(_keyWeeklyStats, json.encode(weekly));

    // Firestore yedek
    _backupToFirestore({
      'today_studied':  todayStudied,
      'current_streak': streak,
      'longest_streak': longest,
      'last_study_date': today,
      'weekly_stats':   weekly,
      'updated_at':     FieldValue.serverTimestamp(),
    });
  }

  // ── Public API ────────────────────────────────────────────────────────────

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
      final newTotal = current + 1;
      await prefs.setInt(_keyFlashcardsStudied, newTotal);
      await _updateDailyActivity(prefs);

      _backupToFirestore({
        'flashcards_studied': newTotal,
        'completed_cards': completed,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyGoal, goal);
    _backupToFirestore({'daily_goal': goal});
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
    _backupToFirestore({
      'weekday_goal_hours': weekdayGoalHours,
      'weekend_goal_hours': weekendGoalHours,
      'target_tus_date':    targetTusDate,
    });
  }

  Future<void> saveScoreGoal({required double base, required double target}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBaseScore, base);
    await prefs.setDouble(_keyTargetScore, target);
    _backupToFirestore({'base_score': base, 'target_score': target});
  }

  Future<void> recordCaseAnswer({String? caseId, required bool correct}) async {
    final prefs = await SharedPreferences.getInstance();

    final attempted = (prefs.getInt(_keyCasesAttempted) ?? 0) + 1;
    await prefs.setInt(_keyCasesAttempted, attempted);

    int correctCount = prefs.getInt(_keyCorrectAnswers) ?? 0;
    if (correct) {
      correctCount++;
      await prefs.setInt(_keyCorrectAnswers, correctCount);
    }

    await _updateDailyActivity(prefs);

    _backupToFirestore({
      'cases_attempted': attempted,
      'correct_answers': correctCount,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordFocusMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyFocusMinutes) ?? 0;
    final newTotal = current + minutes;
    await prefs.setInt(_keyFocusMinutes, newTotal);
    _backupToFirestore({'focus_minutes': newTotal});
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _keyFlashcardsStudied, _keyCasesAttempted, _keyCorrectAnswers,
      _keyCompletedCards, _keyDailyGoal, _keyTodayStudied,
      _keyCurrentStreak, _keyLongestStreak, _keyLastStudyDate,
      _keyWeeklyStats, _keyWeekdayGoalHours, _keyWeekendGoalHours,
      _keyTargetTusDate, _keyBaseScore, _keyTargetScore, _keyFocusMinutes,
    ]) {
      await prefs.remove(key);
    }
    _firestoreDoc?.delete().catchError((_) {});
  }
}
