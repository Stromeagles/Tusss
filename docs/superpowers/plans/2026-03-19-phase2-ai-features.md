# Phase 2 AI Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flashcard ekranına AI mnemonik butonu, ana sayfaya proaktif AI coach notu ve motivasyonel kıyaslama rozeti eklemek.

**Architecture:** `AIService`'e `getMnemonic()` metodu eklenir. `_FlashCardState`'e mnemonic durumu entegre edilir; buton, yükleme göstergesi ve sonuç kutusu `_buildBack()` içinde gösterilir. `AiCoachService` (yeni dosya) SM-2 EF verilerini branşa göre gruplar ve en zayıf branşı tespit eder — saf Dart hesaplama, API bağımlılığı yok. `HomeScreen`'e `_coachInsight` durum alanı, `_buildAiCoachNote()` ve hero kart içinde `_buildRankingBadge()` eklenir.

**Tech Stack:** Flutter 3.41, flutter_animate (mevcut), http (mevcut), AppTheme.neonPurple / AppTheme.neonGold, SharedPreferences (mevcut)

---

## Dosya Haritası

| Dosya | Değişiklik |
|---|---|
| `lib/services/ai_service.dart` | `getMnemonic()` metodu + `_mockMnemonic()` + prompt builder |
| `lib/screens/flashcard_screen.dart` | `_FlashCardState`: mnemonic state + `_generateMnemonic()`; `_buildBack()`: buton/yükleme/sonuç kutusu; yeni alt-widget'lar |
| `lib/services/ai_coach_service.dart` | **YENİ** — `CoachInsight` veri sınıfı + `AiCoachService.analyze()` |
| `lib/screens/home_screen.dart` | `_coachInsight` state + `_loadData()` güncelleme + `_buildAiCoachNote()` + `_buildRankingBadge()` + column sırası |

---

## Task 1: AIService — getMnemonic()

**Files:**
- Modify: `lib/services/ai_service.dart`

- [ ] **Step 1:** `getMnemonic` metodunu `getExplanation`'ın altına ekle

```dart
/// Flashcard için Türkçe mnemonik (ezber kodlama) üretir.
Future<String> getMnemonic(String question, String answer) async {
  if (!ApiConfig.isConfigured) {
    return _mockMnemonic(question, answer);
  }

  final prompt = '''Sen TUS hafıza koçusun. Aşağıdaki flashcard için akılda kalıcı, kısa ve eğlenceli bir Türkçe tekerleme veya kodlama (mnemonic) üret.

Soru: $question
Cevap: $answer

Sadece tekerlemeyi/kodlamayı yaz. Maksimum 2 cümle, Türkçe olsun.''';

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
        return (content.first as Map<String, dynamic>)['text'] as String;
      }
    }
    return '⚠️ Kodlama üretilemedi (HTTP ${response.statusCode}).';
  } on Exception catch (e) {
    return '⚠️ Bağlantı hatası: $e';
  }
}

String _mockMnemonic(String question, String answer) {
  return '💡 "$answer" — Bunu hatırlamak için baş harflerini bir cümleyle '
      'ilişkilendir. API anahtarı eklendiğinde gerçek AI kodlaması üretilecek.';
}
```

- [ ] **Step 2:** `flutter analyze lib/services/ai_service.dart` — hata yok

- [ ] **Step 3:** Commit

```bash
git add lib/services/ai_service.dart
git commit -m "feat(ai): add getMnemonic() to AIService with mock fallback"
```

---

## Task 2: FlashcardScreen — AI Mnemonic Butonu

**Files:**
- Modify: `lib/screens/flashcard_screen.dart`

- [ ] **Step 1:** `_FlashCardState`'e `ai_service` import'unu ve state alanlarını ekle

Dosyanın başındaki import listesine:
```dart
import '../services/ai_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
```

`_FlashCardState` class'ına (diğer field'ların yanına):
```dart
final _aiService = AIService();
String? _mnemonic;
bool _mnemonicLoading = false;
```

- [ ] **Step 2:** `_generateMnemonic()` metodunu `_FlashCardState`'e ekle (dispose'ın altına)

```dart
Future<void> _generateMnemonic() async {
  if (_mnemonicLoading) return;
  setState(() => _mnemonicLoading = true);
  final result = await _aiService.getMnemonic(
    widget.card.question,
    widget.card.answer,
  );
  if (mounted) {
    setState(() {
      _mnemonic = result;
      _mnemonicLoading = false;
    });
  }
}
```

- [ ] **Step 3:** `_buildBack()` içinde `const Spacer()` ile rating row arasına mnemonic bölümünü ekle

Şu an `_buildBack()` şöyle biter:
```dart
          const Spacer(),
          if (widget.onRate != null) ...[
            Row(
```

Bunu şununla değiştir:
```dart
          const Spacer(),
          // AI Mnemonic bölümü
          if (_mnemonicLoading)
            const _ThinkingIndicator()
          else if (_mnemonic != null)
            _MnemonicBox(text: _mnemonic!)
          else
            _MnemonicButton(onTap: _generateMnemonic),
          const SizedBox(height: 12),
          if (widget.onRate != null) ...[
            Row(
```

- [ ] **Step 4:** Dosyanın en altına (son `}` kapanışından önce) 3 yeni widget'ı ekle

`_RatingButton` class'ının hemen altına:
```dart
// ── AI Mnemonic Sub-widgets ────────────────────────────────────────────────

class _MnemonicButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MnemonicButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.neonPurple.withValues(alpha: 0.15),
              AppTheme.neonPurple.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.neonPurple.withValues(alpha: 0.40), width: 1.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🧠', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text(
              'AI Kodlama Üret',
              style: TextStyle(
                color: AppTheme.neonPurple,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.neonPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.25)),
      ),
      child: const Text(
        '🧠 düşünüyor...',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.neonPurple,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1500.ms,
          color: AppTheme.neonPurple.withValues(alpha: 0.20),
        );
  }
}

class _MnemonicBox extends StatelessWidget {
  final String text;
  const _MnemonicBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonPurple.withValues(alpha: 0.12),
            AppTheme.neonPurple.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.neonPurple.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: AppTheme.neonPurple.withValues(alpha: 0.12),
              blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🧠', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              'AI İPUCU',
              style: TextStyle(
                color: AppTheme.neonPurple.withValues(alpha: 0.80),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
```

- [ ] **Step 5:** `flutter analyze lib/screens/flashcard_screen.dart` — hata yok

- [ ] **Step 6:** Commit

```bash
git add lib/screens/flashcard_screen.dart
git commit -m "feat(ai): mnemonic button + thinking indicator + result box on flashcard back"
```

---

## Task 3: AiCoachService — Zayıf Nokta Analizi

**Files:**
- Create: `lib/services/ai_coach_service.dart`

- [ ] **Step 1:** Dosyayı oluştur

```dart
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
```

- [ ] **Step 2:** `flutter analyze lib/services/ai_coach_service.dart` — hata yok

- [ ] **Step 3:** Commit

```bash
git add lib/services/ai_coach_service.dart
git commit -m "feat(ai): add AiCoachService for weakest-subject detection"
```

---

## Task 4: HomeScreen — Coach Notu + Kıyaslama Rozeti

**Files:**
- Modify: `lib/screens/home_screen.dart`

- [ ] **Step 1:** Import ve state alanı ekle

Dosyanın import bloğuna (`goal_settings_screen.dart`'tan sonra):
```dart
import '../services/ai_coach_service.dart';
import '../models/sm2_model.dart';
```

`_HomeScreenState` field'larına (diğerlerinin yanına):
```dart
CoachInsight? _coachInsight;
```

- [ ] **Step 2:** `_loadData()` metodunu güncelle — `getAllData()` Future.wait'e ekle ve coach analizi yap

Eski:
```dart
    final results = await Future.wait([
      _dataService.loadTopics(subjectId: _selectedSubjectId),
      _progressService.loadProgress(),
    ]);
    if (mounted) {
      final topics = results[0] as List<Topic>;
      final progress = results[1] as StudyProgress;

      // Tüm flashcard ve case ID'lerini topla
      final allIds = <String>[];
      for (final t in topics) {
        allIds.addAll(t.flashcards.map((fc) => fc.id));
        allIds.addAll(t.clinicalCases.map((cc) => cc.id).where((id) => id.isNotEmpty));
      }
      final srsSummary = await SpacedRepetitionService().getSummary(allIds);

      setState(() {
        _topics     = topics;
        _progress   = progress;
        _srsSummary = srsSummary;
        _loading    = false;
      });
    }
```

Yeni:
```dart
    final results = await Future.wait([
      _dataService.loadTopics(subjectId: _selectedSubjectId),
      _progressService.loadProgress(),
      SpacedRepetitionService().getAllData(), // SM-2 verisini önbellekle
    ]);
    if (mounted) {
      final topics   = results[0] as List<Topic>;
      final progress = results[1] as StudyProgress;
      final sm2Data  = results[2] as Map<String, SM2CardData>;

      // Tüm flashcard ve case ID'lerini topla
      final allIds = <String>[];
      for (final t in topics) {
        allIds.addAll(t.flashcards.map((fc) => fc.id));
        allIds.addAll(t.clinicalCases.map((cc) => cc.id).where((id) => id.isNotEmpty));
      }
      // getSummary → getAllData önbellekten döner, ekstra I/O yok
      final srsSummary = await SpacedRepetitionService().getSummary(allIds);
      final coachInsight = AiCoachService().analyze(topics, sm2Data);

      setState(() {
        _topics        = topics;
        _progress      = progress;
        _srsSummary    = srsSummary;
        _coachInsight  = coachInsight;
        _loading       = false;
      });
    }
```

- [ ] **Step 3:** `_buildAiCoachNote(bool isDark)` metodunu `_buildStreakBanner`'ın hemen altına ekle

```dart
Widget _buildAiCoachNote(bool isDark) {
  final insight = _coachInsight;
  if (insight == null) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.neonPurple.withValues(alpha: isDark ? 0.15 : 0.08),
              AppTheme.neonGold.withValues(alpha: isDark ? 0.06 : 0.03),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.neonPurple.withValues(alpha: 0.30),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.neonPurple.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.neonPurple.withValues(alpha: 0.35)),
              ),
              child: const Text('🤖', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASISTAN NOTU',
                    style: GoogleFonts.inter(
                      color: AppTheme.neonPurple,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.message,
                    style: GoogleFonts.inter(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05, end: 0);
}
```

- [ ] **Step 4:** `_buildRankingBadge(bool isDark)` metodunu ekle (hero card içinde kullanılacak)

```dart
Widget _buildRankingBadge(bool isDark) {
  final pct = _progress.dailyProgress;
  String label;
  Color color;
  String emoji;

  if (pct >= 0.80) {
    label = 'Bugün en başarılı %10\'luk dilimdesin!';
    color = AppTheme.neonGold;
    emoji = '🏆';
  } else if (pct >= 0.50) {
    label = 'Bugün en iyi %25\'lik dilimdesin!';
    color = AppTheme.neonPurple;
    emoji = '🎯';
  } else if (pct >= 0.20) {
    label = 'Devam et — en iyi %50\'ye girebilirsin!';
    color = AppTheme.cyan;
    emoji = '💪';
  } else {
    return const SizedBox.shrink();
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.12 : 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 5:** `_buildHeroCard` içinde `_buildWeeklyActivity(isDark)` çağrısının altına ranking badge ekle

Eski:
```dart
            const SizedBox(height: 20),
            _buildWeeklyActivity(isDark),
            if (learningCount > 0 || newCount > 0) ...[
```

Yeni:
```dart
            const SizedBox(height: 20),
            _buildWeeklyActivity(isDark),
            const SizedBox(height: 12),
            _buildRankingBadge(isDark),
            if (learningCount > 0 || newCount > 0) ...[
```

- [ ] **Step 6:** Column sırasına `_buildAiCoachNote` ekle (daily goal ile streak banner arasına)

Eski:
```dart
                                  const SizedBox(height: 10),
                                  RepaintBoundary(child: _buildDailyGoal(isDark)),
                                  const SizedBox(height: 16),
                                  _buildStreakBanner(isDark),
```

Yeni:
```dart
                                  const SizedBox(height: 10),
                                  RepaintBoundary(child: _buildDailyGoal(isDark)),
                                  const SizedBox(height: 12),
                                  _buildAiCoachNote(isDark),
                                  const SizedBox(height: 12),
                                  _buildStreakBanner(isDark),
```

- [ ] **Step 7:** `flutter analyze lib/screens/home_screen.dart` — hata yok

- [ ] **Step 8:** Commit

```bash
git add lib/screens/home_screen.dart
git commit -m "feat(ai): AI coach note + ranking badge on home screen"
```

---

## Task 5: Son Kontrol

- [ ] **Step 1:** `flutter analyze lib/` — error olmamalı

- [ ] **Step 2:** Chrome'da `R` (hot restart)

- [ ] **Step 3:** Manuel test:
  - Flashcard arka yüzünde "🧠 AI Kodlama Üret" butonu görünüyor mu?
  - Butona basınca "düşünüyor..." shimmer animasyonu görünüyor mu?
  - Sonuç kutusu neonPurple bordo ile gösteriliyor mu?
  - Ana sayfada coach notu (veri varsa) daily goal altında görünüyor mu?
  - Günlük hedefin %20+ tamamlandıysa hero card'da rozet görünüyor mu?

- [ ] **Step 4:** Final commit

```bash
git add -A
git commit -m "feat: phase 2 AI features — mnemonic generator, coach note, ranking badge"
```
