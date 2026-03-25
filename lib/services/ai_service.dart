import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/topic_model.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // ── In-memory cache (hızlı erişim) ────────────────────────────────────────
  static final Map<String, String> _explanationCache = {};
  static final Map<String, String> _mnemonicCache = {};

  static const _prefsExplanationKey = 'ai_explanation_cache';
  static const _prefsMnemonicKey = 'ai_mnemonic_cache';

  /// Disk'teki cache'i belleğe yükler (app başlangıcında çağrılabilir).
  Future<void> warmUpCache() async {
    if (_explanationCache.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final expJson = prefs.getString(_prefsExplanationKey);
    if (expJson != null) {
      final decoded = json.decode(expJson) as Map<String, dynamic>;
      _explanationCache.addAll(decoded.cast<String, String>());
    }
    final mnJson = prefs.getString(_prefsMnemonicKey);
    if (mnJson != null) {
      final decoded = json.decode(mnJson) as Map<String, dynamic>;
      _mnemonicCache.addAll(decoded.cast<String, String>());
    }
  }

  Future<void> _persistExplanationCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsExplanationKey, json.encode(_explanationCache));
  }

  Future<void> _persistMnemonicCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsMnemonicKey, json.encode(_mnemonicCache));
  }

  // ── Klinik vaka açıklaması ────────────────────────────────────────────────

  Future<String> getExplanation(ClinicalCase clinicalCase) async {
    // 1) Cache kontrol — ID bazlı
    final cacheKey = clinicalCase.id;
    if (_explanationCache.containsKey(cacheKey)) {
      return _explanationCache[cacheKey]!;
    }

    // 2) API yapılandırılmamışsa mock döndür
    if (!ApiConfig.isConfigured) {
      return _mockExplanation(clinicalCase);
    }

    // 3) API çağrısı
    final prompt = _buildPrompt(clinicalCase);
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
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final content = decoded['content'] as List<dynamic>;
        if (content.isNotEmpty) {
          final text = (content.first as Map<String, dynamic>)['text'] as String;
          // Cache'e kaydet (bellek + disk)
          _explanationCache[cacheKey] = text;
          _persistExplanationCache(); // fire-and-forget
          return text;
        }
      }

      if (response.statusCode == 401) {
        return 'API anahtari gecersiz. api_config.dart dosyasindaki anahtari kontrol edin.';
      }
      return 'Aciklama alinamadi (HTTP ${response.statusCode}). Lutfen tekrar deneyin.';
    } on Exception catch (e) {
      return 'Baglanti hatasi: $e\n\nInternet baglantinizi kontrol edin.';
    }
  }

  // ── Flashcard mnemonic ────────────────────────────────────────────────────

  Future<String> getMnemonic(String question, String answer) async {
    final cacheKey = '${question.hashCode}_${answer.hashCode}';
    if (_mnemonicCache.containsKey(cacheKey)) {
      return _mnemonicCache[cacheKey]!;
    }

    if (!ApiConfig.isConfigured) {
      return _mockMnemonic(question, answer);
    }

    final prompt =
        'Sen TUS hafiza kocusun. Asagidaki flashcard icin akilda kalici, kisa ve '
        'eglenceli bir Turkce tekerleme veya kodlama (mnemonic) uret.\n\n'
        'Soru: $question\nCevap: $answer\n\n'
        'Sadece tekerlemeyi/kodlamayi yaz. Maksimum 2 cumle, Turkce olsun.';

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
              'max_tokens': 150,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final content = decoded['content'] as List<dynamic>;
        if (content.isNotEmpty) {
          final text = (content.first as Map<String, dynamic>)['text'] as String;
          _mnemonicCache[cacheKey] = text;
          _persistMnemonicCache();
          return text;
        }
      }
      return 'Kodlama uretilemedi (HTTP ${response.statusCode}).';
    } on Exception catch (e) {
      return 'Baglanti hatasi: $e';
    }
  }

  // ── Prompt builder ────────────────────────────────────────────────────────

  String _buildPrompt(ClinicalCase clinicalCase) {
    return '''Sen TUS (Tipta Uzmanlik Sinavi) hazirlik uygulamasinin tibbi danismanisin.
Asagidaki soruyu kisa, net ve TUS odakli bicimde Turkce acikla.

SORU: ${clinicalCase.caseText}

SECENEKLER: ${clinicalCase.options.join(' / ')}

DOGRU CEVAP: ${clinicalCase.correctAnswer}

Temel aciklama: ${clinicalCase.explanation}

Lutfen su yapiyi kullan:
1. Neden bu cevap dogru? — Patofizyoloji veya mekanizmayi 2-3 cumleyle acikla.
2. Diger secenekler neden yanlis? — Her yanlis secenek icin kisa bir not ekle.
3. TUS icin hatirla: — Bu konuyla ilgili 1-2 kritik puf nokta yaz.

Yanitin maksimum 250 kelime olsun, teknik ama anlasilir bir dil kullan.''';
  }

  String _mockExplanation(ClinicalCase clinicalCase) {
    return '''Neden bu cevap dogru?
${clinicalCase.explanation}

Diger secenekler neden yanlis?
${clinicalCase.options.where((o) => o != clinicalCase.correctAnswer).map((o) => '- $o: Bu secenek ilgili tanimla ortusmuyor.').join('\n')}

TUS icin hatirla:
- Bu konuyu mutlaka kaynaklarda detayli calis.
- Benzer sorularda mekanizmayi ve klinik onemi birlikte dusun.

(AI aciklamalari icin api_config.dart dosyasina Claude API anahtarinizi ekleyin.)''';
  }

  String _mockMnemonic(String question, String answer) {
    return '"$answer" — Bunu hatirlamak icin bas harflerini bir cumleyle '
        'iliskilendir. API anahtari eklendiginde gercek AI kodlamasi uretilecek.';
  }

  // ── Kontekstüel AI Soru-Cevap ──────────────────────────────────────────

  /// Kullanıcı bir flashcard/case üzerindeyken serbest soru sorabilir.
  /// [cardContext]: Mevcut soru + cevap özeti
  /// [userQuestion]: Kullanıcının sorusu
  /// [chatHistory]: Önceki mesajlar (multi-turn conversation)
  Future<String> askContextualQuestion({
    required String cardContext,
    required String userQuestion,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    if (!ApiConfig.isConfigured) {
      return 'Bu özellik için Claude API anahtarı gereklidir. '
          'api_config.dart dosyasına anahtarınızı ekleyin.';
    }

    final systemPrompt =
        'Sen TUS (Tıpta Uzmanlık Sınavı) hazırlık uygulamasının tıbbi danışmanısın. '
        'Kullanıcı şu anda aşağıdaki soruyu/kartı çalışıyor:\n\n'
        '--- KART İÇERİĞİ ---\n$cardContext\n--- KART SONU ---\n\n'
        'Kullanıcının bu kartla ilgili sorularını Türkçe, kısa ve TUS odaklı yanıtla. '
        'Maksimum 200 kelime kullan. Klinik korelasyon ve ayırıcı tanı bilgisi ekle.';

    // Build messages array (system + history + new question)
    final messages = <Map<String, String>>[
      ...chatHistory,
      {'role': 'user', 'content': userQuestion},
    ];

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
              'max_tokens': 400,
              'system': systemPrompt,
              'messages': messages,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final content = decoded['content'] as List<dynamic>;
        if (content.isNotEmpty) {
          return (content.first as Map<String, dynamic>)['text'] as String;
        }
      }
      return 'Yanıt alınamadı (HTTP ${response.statusCode}).';
    } on Exception catch (e) {
      return 'Bağlantı hatası: $e';
    }
  }

  // ── Zayıflık / Hata Örüntüsü Analizi ────────────────────────────────────

  /// SM-2 hata özetini alır, AI ile tıbbi örüntü + eksik kapatma planı üretir.
  /// [failureReport] formatı: "Branş: N hata\n  - Konu (M)\n..."
  Future<String> analyzeWeakness(String failureReport) async {
    if (!ApiConfig.isConfigured) {
      return _fallbackWeaknessAnalysis(failureReport);
    }

    const systemPrompt =
        'Sen deneyimli bir TUS sınav koçusun. Türkçe yanıt ver. '
        'Kısa, pratik ve öğrenciye özgü ol. Markdown kullan.';

    final userMsg =
        'Aşağıda TUS adayının SM-2 sistemindeki hata kayıtları var.\n\n'
        'HATA RAPORU:\n$failureReport\n\n'
        'Şunları yap:\n'
        '1. **Örüntü Analizi**: 2-3 cümleyle hataların ardındaki kavram karışıklığını '
        'açıkla. "Genelde X branşında Y konuyu Z ile karıştırıyorsun" formatında '
        'spesifik ol.\n'
        '2. **Kritik TUS Spotları**: En kritik 3 branş için birer hatırlama noktası ver.\n'
        '3. **Eksik Kapatma Planı**: Öncelikli 3 aksiyon öner (her biri max 1 cümle).\n\n'
        'Format:\n'
        '### 🔍 Örüntü Analizi\n[metin]\n\n'
        '### 💡 Kritik TUS Spotları\n- **[Branş]**: [spot]\n\n'
        '### 📋 Eksik Kapatma Planı\n1. [aksiyon]\n2. [aksiyon]\n3. [aksiyon]';

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
              'max_tokens': 900,
              'system': systemPrompt,
              'messages': [
                {'role': 'user', 'content': userMsg},
              ],
            }),
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final content = decoded['content'] as List<dynamic>;
        if (content.isNotEmpty) {
          return (content.first as Map<String, dynamic>)['text'] as String;
        }
      }
      return _fallbackWeaknessAnalysis(failureReport);
    } on Exception {
      return _fallbackWeaknessAnalysis(failureReport);
    }
  }

  String _fallbackWeaknessAnalysis(String report) {
    final lines = report.trim().split('\n');
    final branches = lines
        .where((l) => !l.startsWith(' ') && l.contains(':'))
        .map((l) => l.split(':').first.trim())
        .take(3)
        .toList();
    final branchText = branches.isEmpty ? 'çeşitli branşlarda' : branches.join(', ');
    return '### 🔍 Örüntü Analizi\n'
        '$branchText alanlarında hata yoğunluğu görülüyor. '
        'Bu alanlarda kavram netleştirmesine ihtiyaç var.\n\n'
        '### 💡 Kritik TUS Spotları\n'
        '${branches.map((b) => '- **$b**: Bu branşın temel mekanizmalarını tekrar gözden geçir.').join('\n')}\n\n'
        '### 📋 Eksik Kapatma Planı\n'
        '1. Hata yaptığın kartları "Yanlışlar" modunda çalış.\n'
        '2. Her yanlış sorunun açıklamasını dikkatlice oku.\n'
        '3. Zayıf branşlarda günlük en az 10 kart hedefle.';
  }

  /// Cache istatistikleri (debug icin)
  int get cachedExplanations => _explanationCache.length;
  int get cachedMnemonics => _mnemonicCache.length;

  void clearCache() {
    _explanationCache.clear();
    _mnemonicCache.clear();
  }
}
