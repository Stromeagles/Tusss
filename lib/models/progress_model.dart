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
  final List<String> selectedSubjectIds; // Seçili branş ID'leri

  // Hedef ayarları
  final double weekdayGoalHours;  // Hafta içi günlük saat hedefi
  final double weekendGoalHours;  // Hafta sonu günlük saat hedefi
  final String targetTusDate;     // Hedef TUS sınav tarihi (YYYY-MM-DD)
  
  // Puan bazlı hedefleme
  final double baseScore;
  final double targetScore;

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
    this.selectedSubjectIds = const [],
    this.baseScore = 45.0,
    this.targetScore = 65.0,
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
      final diff = target.difference(DateTime.now()).inDays;
      return diff.clamp(1, 9999); // En az 1 gün kalsın ki bölme hatası olmasın
    } catch (_) {
      return 1;
    }
  }

  /// Puan hedefine göre önerilen günlük soru sayısı
  /// Puan arttıkça bir puan almanın zorluğu (çalışma yükü) logaritmik/üstel artar.
  int get recommendedDailyGoal {
    final pointsToGain = (targetScore - baseScore).clamp(0.0, 100.0);
    final days = daysToExam;
    if (days <= 0) return 100;
    
    // Ortalama puan (hedeflenen seviye)
    final avgScore = (baseScore + targetScore) / 2;
    
    // Zorluk katsayısı: 40 puanda 1.0x, 70 puanda ~2.0x, 80 puanda ~3.0x maliyet
    // Puan arttıkça her bir puanı kazanmak için gereken soru sayısı artar.
    final difficultyMultiplier = 1.0 + ((avgScore - 40).clamp(0, 50) * (avgScore - 40).clamp(0, 50) / 800);
    
    final totalItemsNeeded = pointsToGain * 1000 * difficultyMultiplier;
    return (totalItemsNeeded / days).ceil().clamp(20, 500);
  }

  /// Puan hedefine göre "hırs" seviyesi
  String get scoreIntensity {
    if (targetScore >= 75) return 'Efsane'; // Derece hedefi
    if (targetScore >= 65) return 'Uzman';  // İyi bir branş hedefi
    if (targetScore >= 55) return 'Gelişmiş'; // Baraj üstü sağlam hedef
    return 'Standart';
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
    List<String>? selectedSubjectIds,
    double? baseScore,
    double? targetScore,
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
      selectedSubjectIds: selectedSubjectIds ?? this.selectedSubjectIds,
      baseScore: baseScore ?? this.baseScore,
      targetScore: targetScore ?? this.targetScore,
    );
  }
}
