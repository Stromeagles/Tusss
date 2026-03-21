/// Spaced Repetition kart verisi — Dinamik SM-2 Algoritması
/// 1 (Bilemedim): Aralık 1 güne düşer, Ease Factor azalır
/// 2 (Bildim):    Aralık geometrik artar (interval × easeFactor)
class SM2CardData {
  final String cardId;
  final int repetitions;
  final int interval;
  final double easeFactor;
  final DateTime nextReviewDate;
  final int? lastQuality; // 1 = Bilemedim, 2 = Bildim
  final bool isBookmarked;

  const SM2CardData({
    required this.cardId,
    this.repetitions = 0,
    this.interval = 1,
    this.easeFactor = 2.5,
    required this.nextReviewDate,
    this.lastQuality,
    this.isBookmarked = false,
  });

  bool get isDue {
    final today = DateTime.now();
    return !nextReviewDate
        .isAfter(DateTime(today.year, today.month, today.day));
  }

  /// quality: 1 = Bilemedim, 2 = Bildim
  /// Bilemedim → aralık 1 güne düşer, ease azalır (min 1.3)
  /// Bildim → aralık geometrik artar (interval × easeFactor), ease artar
  SM2CardData computeNext(int quality) {
    assert(quality == 1 || quality == 2);

    int newInterval;
    int newReps;
    double newEase;

    if (quality == 1) {
      // Bilemedim: sıfırla, ease azalt
      newInterval = 1;
      newReps = 0;
      newEase = (easeFactor - 0.2).clamp(1.3, 5.0);
    } else {
      // Bildim: geometrik artış
      newReps = repetitions + 1;
      newEase = (easeFactor + 0.1).clamp(1.3, 5.0);
      if (repetitions == 0) {
        newInterval = 1;
      } else if (repetitions == 1) {
        newInterval = 3;
      } else {
        newInterval = (interval * easeFactor).round();
      }
    }

    final nextDate = DateTime.now().add(Duration(days: newInterval));
    return SM2CardData(
      cardId:         cardId,
      repetitions:    newReps,
      interval:       newInterval,
      easeFactor:     newEase,
      nextReviewDate: DateTime(nextDate.year, nextDate.month, nextDate.day),
      lastQuality:    quality,
      isBookmarked:   isBookmarked,
    );
  }

  SM2CardData copyWithBookmark(bool value) => SM2CardData(
    cardId:         cardId,
    repetitions:    repetitions,
    interval:       interval,
    easeFactor:     easeFactor,
    nextReviewDate: nextReviewDate,
    lastQuality:    lastQuality,
    isBookmarked:   value,
  );

  Map<String, dynamic> toJson() => {
    'cardId':         cardId,
    'repetitions':    repetitions,
    'interval':       interval,
    'easeFactor':     easeFactor,
    'nextReviewDate': nextReviewDate.toIso8601String(),
    'lastQuality':    lastQuality,
    'isBookmarked':   isBookmarked,
  };

  factory SM2CardData.fromJson(Map<String, dynamic> json) => SM2CardData(
    cardId:         json['cardId'] as String,
    repetitions:    (json['repetitions'] as int?) ?? 0,
    interval:       (json['interval'] as int?) ?? 1,
    easeFactor:     (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
    nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
    lastQuality:    json['lastQuality'] as int?,
    isBookmarked:   (json['isBookmarked'] as bool?) ?? false,
  );

  factory SM2CardData.initial(String cardId) => SM2CardData(
    cardId:         cardId,
    nextReviewDate: DateTime.now(),
  );
}
