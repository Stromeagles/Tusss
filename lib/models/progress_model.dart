class StudyProgress {
  final int totalFlashcardsStudied;
  final int totalCasesAttempted;
  final int correctAnswers;
  final Map<String, bool> completedFlashcards; // flashcard id -> seen

  // Yeni özellikler
  final int dailyGoal; // Günlük hedef kart sayısı
  final int todayStudied; // Bugün çalışılan kart sayısı
  final int currentStreak; // Ardışık çalışma günleri
  final int longestStreak; // En uzun streak
  final String lastStudyDate; // Son çalışma tarihi (YYYY-MM-DD)
  final Map<String, int> weeklyStats; // Haftalık istatistikler (tarih -> kart sayısı)

  // Hedef ayarları
  final double weekdayGoalHours;  // Hafta içi günlük saat hedefi
  final double weekendGoalHours;  // Hafta sonu günlük saat hedefi
  final String targetTusDate;     // Hedef TUS sınav tarihi (YYYY-MM-DD)

  const StudyProgress({
    this.totalFlashcardsStudied = 0,
    this.totalCasesAttempted = 0,
    this.correctAnswers = 0,
    this.completedFlashcards = const {},
    this.dailyGoal = 50,
    this.todayStudied = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudyDate = '',
    this.weeklyStats = const {},
    this.weekdayGoalHours = 2.0,
    this.weekendGoalHours = 4.0,
    this.targetTusDate = '2026-06-28',
  });

  double get accuracy => totalCasesAttempted == 0
      ? 0
      : (correctAnswers / totalCasesAttempted) * 100;

  double get dailyProgress => dailyGoal == 0
      ? 0
      : (todayStudied / dailyGoal).clamp(0.0, 1.0);

  bool get dailyGoalCompleted => todayStudied >= dailyGoal;

  /// Bugün hafta içi mi hafta sonu mu — buna göre saat hedefini döner
  double get todayGoalHours {
    final wd = DateTime.now().weekday; // 1=Pzt ... 5=Cum, 6=Cmt, 7=Paz
    return (wd >= 6) ? weekendGoalHours : weekdayGoalHours;
  }

  /// Hedef TUS tarihine kalan gün
  int get daysToExam {
    try {
      final target = DateTime.parse(targetTusDate);
      return target.difference(DateTime.now()).inDays.clamp(0, 9999);
    } catch (_) {
      return 0;
    }
  }

  StudyProgress copyWith({
    int? totalFlashcardsStudied,
    int? totalCasesAttempted,
    int? correctAnswers,
    Map<String, bool>? completedFlashcards,
    int? dailyGoal,
    int? todayStudied,
    int? currentStreak,
    int? longestStreak,
    String? lastStudyDate,
    Map<String, int>? weeklyStats,
    double? weekdayGoalHours,
    double? weekendGoalHours,
    String? targetTusDate,
  }) {
    return StudyProgress(
      totalFlashcardsStudied:
          totalFlashcardsStudied ?? this.totalFlashcardsStudied,
      totalCasesAttempted: totalCasesAttempted ?? this.totalCasesAttempted,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      completedFlashcards: completedFlashcards ?? this.completedFlashcards,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      todayStudied: todayStudied ?? this.todayStudied,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      weekdayGoalHours: weekdayGoalHours ?? this.weekdayGoalHours,
      weekendGoalHours: weekendGoalHours ?? this.weekendGoalHours,
      targetTusDate: targetTusDate ?? this.targetTusDate,
    );
  }
}
