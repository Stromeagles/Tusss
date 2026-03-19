import '../models/topic_model.dart';
import '../models/sm2_model.dart';

/// Kullanıcının en çok zorlandığı branşı SM-2 verilerine bakarak tespit eder.
/// Tamamen yerel hesaplama — API bağımlılığı yok.
class CoachInsight {
  final String subjectName;
  final String message;

  const CoachInsight({required this.subjectName, required this.message});
}

class AiCoachService {
  static final AiCoachService _instance = AiCoachService._internal();
  factory AiCoachService() => _instance;
  AiCoachService._internal();

  /// [topics]: HomeScreen'de zaten yüklü olan topic listesi.
  /// [sm2Data]: SpacedRepetitionService.getAllData() çıktısı (önbellekli).
  /// Döner: null → analiz için yeterli veri yok (hiç çalışılmamış)
  CoachInsight? analyze(
      List<Topic> topics, Map<String, SM2CardData> sm2Data) {
    if (topics.isEmpty || sm2Data.isEmpty) return null;

    // Kart ID'lerini branşa göre grupla (topic.subject string'i anahtar)
    final Map<String, List<String>> subjectCards = {};
    for (final topic in topics) {
      subjectCards.putIfAbsent(topic.subject, () => []);
      for (final fc in topic.flashcards) {
        subjectCards[topic.subject]!.add(fc.id);
      }
    }

    // Her branşın görülmüş kartlarının ortalama easeFactor'ünü hesapla
    String? weakestSubject;
    double lowestEF = double.infinity;

    for (final entry in subjectCards.entries) {
      final seen = entry.value
          .where((id) => sm2Data.containsKey(id))
          .map((id) => sm2Data[id]!)
          .toList();

      if (seen.isEmpty) continue; // henüz çalışılmamış branş — atla

      final avgEF =
          seen.fold(0.0, (sum, c) => sum + c.easeFactor) / seen.length;

      if (avgEF < lowestEF) {
        lowestEF = avgEF;
        weakestSubject = entry.key;
      }
    }

    if (weakestSubject == null) return null;

    // Ortalama EF 2.3'ün altındaysa zorlandığını gösterir
    if (lowestEF >= 2.3) return null;

    return CoachInsight(
      subjectName: weakestSubject,
      message: _buildMessage(weakestSubject, lowestEF),
    );
  }

  String _buildMessage(String subject, double avgEF) {
    if (avgEF < 1.7) {
      return 'Dostum, $subject konusundaki bazı kartlar sana direnç gösteriyor. '
          'Bugün o kartlara 10–15 dakika odaklansan çok fark yaratır. '
          'Az ama sık tekrar, uzun vadede çok işe yarıyor! 💪';
    }
    return '$subject\'da biraz titiz davranıyorsun — bu iyi bir işaret! '
        'Bugün o branşı bir kez daha gözden geçirsen yeterli olur. '
        'Başarıyorsun! 🎯';
  }
}
