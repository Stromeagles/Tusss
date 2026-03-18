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
  });

  double get accuracy => totalCasesAttempted == 0
      ? 0
      : (correctAnswers / totalCasesAttempted) * 100;

  double get dailyProgress => dailyGoal == 0
      ? 0
      : (todayStudied / dailyGoal).clamp(0.0, 1.0);

  bool get dailyGoalCompleted => todayStudied >= dailyGoal;

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
    );
  }
}
