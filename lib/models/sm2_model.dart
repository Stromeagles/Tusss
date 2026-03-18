/// SM-2 Spaced Repetition algoritması için kart verisi.
///
/// Algoritma: SuperMemo 2 (SM-2)
/// Kaynak: https://www.supermemo.com/en/archives1990-2015/english/ol/sm2
class SM2CardData {
  final String cardId;

  /// Easiness Factor — başlangıç: 2.5, minimum: 1.3
  final double easeFactor;

  /// Kaç kez doğru yanıtlandı (arka arkaya)
  final int repetitions;

  /// Gün cinsinden tekrar aralığı
  final int interval;

  /// Bir sonraki gösterim tarihi (UTC, sadece tarih kısmı önemli)
  final DateTime nextReviewDate;

  const SM2CardData({
    required this.cardId,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.interval = 1,
    required this.nextReviewDate,
  });

  /// Kartın bugün veya daha önce görülmesi gerekiyor mu?
  bool get isDue {
    final today = DateTime.now();
    final due = nextReviewDate;
    return !due.isAfter(DateTime(today.year, today.month, today.day));
  }

  /// SM-2: quality 0-5 (0=hiç hatırlamadım, 5=mükemmel)
  /// Uygulamamızda: sağ kaydır = 4, sol kaydır = 1
  SM2CardData computeNext(int quality) {
    assert(quality >= 0 && quality <= 5);

    double newEF =
        easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEF < 1.3) newEF = 1.3;

    int newRepetitions;
    int newInterval;

    if (quality < 3) {
      // Yanlış yanıt → sıfırla
      newRepetitions = 0;
      newInterval = 1;
    } else {
      newRepetitions = repetitions + 1;
      if (repetitions == 0) {
        newInterval = 1;
      } else if (repetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (interval * newEF).round();
      }
    }

    final nextDate = DateTime.now().add(Duration(days: newInterval));

    return SM2CardData(
      cardId: cardId,
      easeFactor: newEF,
      repetitions: newRepetitions,
      interval: newInterval,
      nextReviewDate:
          DateTime(nextDate.year, nextDate.month, nextDate.day),
    );
  }

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'easeFactor': easeFactor,
        'repetitions': repetitions,
        'interval': interval,
        'nextReviewDate': nextReviewDate.toIso8601String(),
      };

  factory SM2CardData.fromJson(Map<String, dynamic> json) {
    return SM2CardData(
      cardId: json['cardId'] as String,
      easeFactor: (json['easeFactor'] as num).toDouble(),
      repetitions: json['repetitions'] as int,
      interval: json['interval'] as int,
      nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
    );
  }

  factory SM2CardData.initial(String cardId) {
    return SM2CardData(
      cardId: cardId,
      nextReviewDate: DateTime.now(),
    );
  }
}
