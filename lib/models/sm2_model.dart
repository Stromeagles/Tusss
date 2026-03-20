/// Spaced Repetition kart verisi — Sade 2 Seçenek
/// 1 (Bilemedim): 1 gün sonra tekrar
/// 2 (Bildim):    3 gün sonra tekrar
class SM2CardData {
  final String cardId;
  final int repetitions;
  final int interval;
  final DateTime nextReviewDate;
  final int? lastQuality; // 1 = Bilemedim, 2 = Bildim
  final bool isBookmarked;

  const SM2CardData({
    required this.cardId,
    this.repetitions = 0,
    this.interval = 1,
    required this.nextReviewDate,
    this.lastQuality,
    this.isBookmarked = false,
  });

  bool get isDue {
    final today = DateTime.now();
    return !nextReviewDate
        .isAfter(DateTime(today.year, today.month, today.day));
  }

  /// quality: 1 = Bilemedim (1 gün), 2 = Bildim (3 gün)
  SM2CardData computeNext(int quality) {
    assert(quality == 1 || quality == 2);
    final newInterval = quality == 1 ? 1 : 3;
    final newReps     = quality == 1 ? 0 : repetitions + 1;
    final nextDate    = DateTime.now().add(Duration(days: newInterval));
    return SM2CardData(
      cardId:         cardId,
      repetitions:    newReps,
      interval:       newInterval,
      nextReviewDate: DateTime(nextDate.year, nextDate.month, nextDate.day),
      lastQuality:    quality,
      isBookmarked:   isBookmarked,
    );
  }

  SM2CardData copyWithBookmark(bool value) => SM2CardData(
    cardId:         cardId,
    repetitions:    repetitions,
    interval:       interval,
    nextReviewDate: nextReviewDate,
    lastQuality:    lastQuality,
    isBookmarked:   value,
  );

  Map<String, dynamic> toJson() => {
    'cardId':         cardId,
    'repetitions':    repetitions,
    'interval':       interval,
    'nextReviewDate': nextReviewDate.toIso8601String(),
    'lastQuality':    lastQuality,
    'isBookmarked':   isBookmarked,
  };

  factory SM2CardData.fromJson(Map<String, dynamic> json) => SM2CardData(
    cardId:         json['cardId'] as String,
    repetitions:    (json['repetitions'] as int?) ?? 0,
    interval:       (json['interval'] as int?) ?? 1,
    nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
    lastQuality:    json['lastQuality'] as int?,
    isBookmarked:   (json['isBookmarked'] as bool?) ?? false,
  );

  factory SM2CardData.initial(String cardId) => SM2CardData(
    cardId:         cardId,
    nextReviewDate: DateTime.now(),
  );
}
