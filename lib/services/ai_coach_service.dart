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

    // Her branşın görülmüş kartlarında "Bilemedim" oranını hesapla (yüksek = zayıf)
    String? weakestSubject;
    double highestFailRatio = 0.0;

    for (final entry in subjectCards.entries) {
      final seen = entry.value
          .where((id) => sm2Data.containsKey(id))
          .map((id) => sm2Data[id]!)
          .toList();

      if (seen.isEmpty) continue; // henüz çalışılmamış branş — atla

      final failCount = seen.where((c) => c.lastQuality == 1).length;
      final failRatio = failCount / seen.length;

      if (failRatio > highestFailRatio) {
        highestFailRatio = failRatio;
        weakestSubject = entry.key;
      }
    }

    if (weakestSubject == null) return null;

    // Bilemedim oranı %30'un üzerindeyse zorlandığını gösterir
    if (highestFailRatio < 0.30) return null;

    return CoachInsight(
      subjectName: weakestSubject,
      message: _buildMessage(weakestSubject, highestFailRatio),
    );
  }

  String _buildMessage(String subject, double failRatio) {
    if (failRatio > 0.60) {
      return 'Dostum, $subject konusundaki bazı kartlar sana direnç gösteriyor. '
          'Bugün o kartlara 10–15 dakika odaklansan çok fark yaratır. '
          'Az ama sık tekrar, uzun vadede çok işe yarıyor! 💪';
    }
    return '$subject\'da biraz zorlandığın kartlar var — bu normale! '
        'Bugün o branşı bir kez daha gözden geçirsen yeterli olur. '
        'Başarıyorsun! 🎯';
  }
}
