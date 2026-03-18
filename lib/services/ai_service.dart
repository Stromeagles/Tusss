import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/topic_model.dart';
import '../utils/app_logger.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// Klinik vaka için Claude'dan detaylı tıbbi açıklama ister.
  Future<String> getExplanation(ClinicalCase clinicalCase) async {
    if (!ApiConfig.isConfigured) {
      return _mockExplanation(clinicalCase);
    }

    final prompt = _buildPrompt(clinicalCase);

    AppLogger.info('AIService', 'getExplanation başlatılıyor: ${clinicalCase.caseText.substring(0, clinicalCase.caseText.length.clamp(0, 60))}...');
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.anthropicBaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': ApiConfig.anthropicApiKey,
              'anthropic-version': ApiConfig.anthropicVersion,
            },
            body: json.encode({
              'model': ApiConfig.claudeModel,
              'max_tokens': 600,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final content = decoded['content'] as List<dynamic>;
        if (content.isNotEmpty) {
          AppLogger.info('AIService', 'Açıklama başarıyla alındı.');
          return (content.first as Map<String, dynamic>)['text'] as String;
        }
        AppLogger.warning('AIService', 'API yanıtı boş content döndürdü.');
        return '⚠️ Açıklama alınamadı. Lütfen tekrar deneyin.';
      }

      // API hatası → kullanıcıya anlamlı mesaj döndür
      if (response.statusCode == 401) {
        AppLogger.error('AIService', 'API anahtarı geçersiz (HTTP 401).');
        return '⚠️ API anahtarı geçersiz. `lib/config/api_config.dart` dosyasındaki anahtarı kontrol edin.';
      }
      AppLogger.error('AIService', 'HTTP hata kodu: ${response.statusCode}');
      return '⚠️ Açıklama alınamadı (HTTP ${response.statusCode}). Lütfen tekrar deneyin.';
    } on Exception catch (e, st) {
      AppLogger.error('AIService', 'Bağlantı hatası', e, st);
      return '⚠️ Bağlantı hatası: $e\n\nİnternet bağlantınızı kontrol edin.';
    }
  }

  String _buildPrompt(ClinicalCase clinicalCase) {
    return '''Sen TUS (Tıpta Uzmanlık Sınavı) hazırlık uygulamasının tıbbi danışmanısın.
Aşağıdaki soruyu kısa, net ve TUS odaklı biçimde Türkçe açıkla.

SORU: ${clinicalCase.caseText}

SEÇENEKLER: ${clinicalCase.options.join(' / ')}

DOĞRU CEVAP: ${clinicalCase.correctAnswer}

Temel açıklama: ${clinicalCase.explanation}

Lütfen şu yapıyı kullan:
1. **Neden bu cevap doğru?** — Patofizyoloji veya mekanizmayı 2-3 cümleyle açıkla.
2. **Diğer seçenekler neden yanlış?** — Her yanlış seçenek için kısa bir not ekle.
3. **TUS için hatırla:** — Bu konuyla ilgili 1-2 kritik püf nokta yaz.

Yanıtın maksimum 250 kelime olsun, teknik ama anlaşılır bir dil kullan.''';
  }

  /// API yapılandırılmamışsa gösterilecek örnek yanıt.
  String _mockExplanation(ClinicalCase clinicalCase) {
    return '''**Neden bu cevap doğru?**
${clinicalCase.explanation} Bu mekanizma, TUS'ta sıklıkla sorulan temel mikrobiyoloji konularından biridir.

**Diğer seçenekler neden yanlış?**
${clinicalCase.options.where((o) => o != clinicalCase.correctAnswer).map((o) => '• **$o:** Bu seçenek ilgili tanımla örtüşmez.').join('\n')}

**TUS için hatırla:**
• Bu konuyu mutlaka kaynaklarda detaylı çalış.
• Benzer sorularda mekanizmayı ve klinik önemi birlikte düşün.

---
*ℹ️ AI açıklamaları için `api_config.dart` dosyasına Claude API anahtarınızı ekleyin.*''';
  }
}
