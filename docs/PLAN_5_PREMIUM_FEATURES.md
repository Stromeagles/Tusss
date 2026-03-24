# TUS Asistanı — 5 Premium Özellik Mimari Yol Haritası

> Hazırlayan: Senior Flutter & UX Architect
> Tarih: 2026-03-23
> Durum: Onay Bekliyor

---

## Genel Mimari Prensipler

- Mevcut **Singleton Service + Provider** pattern'i korunacak
- Tüm persistence **SharedPreferences** üzerinden (mevcut altyapı ile tutarlı)
- Yeni ekranlar mevcut `AppTheme` glassmorphism + gradient background'u kullanacak
- Her özellik bağımsız commit'lenebilir, birbirine bağımlılık minimum
- Freemium limitleri `PremiumService` üzerinden genişletilecek

---

## Uygulama Sırası ve Gerekçesi

| Sıra | Özellik | Öncelik Gerekçesi |
|------|---------|-------------------|
| **1** | Soru İçi Kontekstüel AI Asistanı | Mevcut `AIService` üzerine inşa edilir, en düşük riskli |
| **2** | Kullanıcıya Özel Soru Klasörleri | `SpacedRepetitionService.bookmark` yapısını genişletir |
| **3** | Kaydırılabilir Spot/Hap Bilgiler | Mevcut JSON `tusSpots` verisini kullanır, yeni veri gerekmez |
| **4** | Gerçek Süreli Deneme Sınavı | En kapsamlı modül — model, servis, ekran, timer mantığı |
| **5** | Liderlik Tablosu / Gamification | Firebase Firestore gerektirir, en yüksek altyapı bağımlılığı |

---

## Özellik 1: Soru İçi Kontekstüel AI Asistanı

### Amaç
Kullanıcı bir flashcard veya klinik vaka çözerken, o soruya özel serbest metin sorusu sorabilecek. Örn: *"Bu bakterinin diğer toksinleri nelerdir?"*, *"Neden E şıkkı yanlış?"*

### Yeni Dosyalar

| Dosya | Konum | Açıklama |
|-------|-------|----------|
| `ai_chat_sheet.dart` | `lib/widgets/` | Soru bazlı AI sohbet bottom sheet widget'ı |

### Değiştirilecek Dosyalar

| Dosya | Değişiklik |
|-------|-----------|
| `lib/services/ai_service.dart` | Yeni `askContextualQuestion(context, question)` metodu eklenir |
| `lib/screens/flashcard_screen.dart` | Kart üzerinde "AI'ya Sor" butonu + sheet entegrasyonu |
| `lib/screens/case_study_screen.dart` | Vaka ekranında "AI'ya Sor" butonu + sheet entegrasyonu |

### Mimari Detay

```
┌──────────────────────────────────────────────┐
│  FlashcardScreen / CaseStudyScreen           │
│  ┌────────────────────────────────────────┐   │
│  │  Mevcut kart/soru UI                   │   │
│  │  ┌──────────────────────────┐          │   │
│  │  │ 🤖 "AI'ya Sor" FAB      │──────────┤   │
│  │  └──────────────────────────┘          │   │
│  └────────────────────────────────────────┘   │
│                    │                          │
│                    ▼                          │
│  ┌────────────────────────────────────────┐   │
│  │  AiChatSheet (BottomSheet)             │   │
│  │  ┌─────────────────────────────────┐   │   │
│  │  │ Kontekst: Soru + Cevap özeti   │   │   │
│  │  ├─────────────────────────────────┤   │   │
│  │  │ Chat mesaj listesi (soru/cevap) │   │   │
│  │  ├─────────────────────────────────┤   │   │
│  │  │ TextField + Gönder butonu       │   │   │
│  │  └─────────────────────────────────┘   │   │
│  └────────────────────────────────────────┘   │
└──────────────────────────────────────────────┘
```

**AIService Genişletmesi:**
```dart
// Yeni metot imzası
Future<String> askContextualQuestion({
  required String cardContext,   // Soru + cevap özeti
  required String userQuestion,  // Kullanıcının sorusu
  List<Map<String, String>> chatHistory = const [], // Önceki mesajlar
}) async { ... }
```

- **Prompt**: Sistem mesajında kart konteksti verilir, kullanıcı sorusu gönderilir
- **Cache**: Kontekstüel sorular cache'lenmez (her soru farklı)
- **Token Limit**: max_tokens: 400
- **Freemium**: Günlük 10 AI soru hakkı (free), premium sınırsız

### Veri Akışı
```
Kullanıcı → "Neden A şıkkı yanlış?" yazıp gönderir
  → AiChatSheet → AIService.askContextualQuestion(
      cardContext: "Soru: X, Cevap: Y",
      userQuestion: "Neden A şıkkı yanlış?",
      chatHistory: [...önceki mesajlar...]
    )
  → Anthropic API (claude-haiku-4-5)
  → Cevap AiChatSheet'te gösterilir
```

---

## Özellik 2: Kullanıcıya Özel Soru Klasörleri / Koleksiyonları

### Amaç
Kullanıcı kendi özel klasörleri oluşturabilecek (örn: "Zor Bakteriler", "Sınav Öncesi Tekrar") ve flashcard/case'leri bu klasörlere ekleyebilecek. Mevcut tek "bookmark" sistemi → çoklu klasör sistemine evrilir.

### Yeni Dosyalar

| Dosya | Konum | Açıklama |
|-------|-------|----------|
| `collection_model.dart` | `lib/models/` | Klasör veri modeli |
| `collection_service.dart` | `lib/services/` | CRUD + persistence |
| `collections_screen.dart` | `lib/screens/` | Klasör listesi ekranı |
| `collection_detail_screen.dart` | `lib/screens/` | Klasör içi kartlar |
| `add_to_collection_sheet.dart` | `lib/widgets/` | Klasöre ekleme bottom sheet |

### Değiştirilecek Dosyalar

| Dosya | Değişiklik |
|-------|-----------|
| `lib/screens/flashcard_screen.dart` | Kart üzerinde "Klasöre Ekle" butonu |
| `lib/screens/case_study_screen.dart` | Vaka üzerinde "Klasöre Ekle" butonu |
| `lib/screens/home_screen.dart` | Klasörler bölümü / navigasyon |

### Model Tasarımı

```dart
class CardCollection {
  final String id;            // UUID
  final String name;          // "Zor Bakteriler"
  final String emoji;         // "🦠"
  final Color color;          // Etiket rengi
  final List<String> cardIds; // Flashcard + Case ID'leri karışık
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Service Tasarımı

```dart
class CollectionService {
  // Singleton pattern (mevcut servislerle tutarlı)

  List<CardCollection> getAll();
  CardCollection? getById(String id);

  Future<void> createCollection(String name, String emoji, Color color);
  Future<void> deleteCollection(String id);
  Future<void> renameCollection(String id, String newName);

  Future<void> addCard(String collectionId, String cardId);
  Future<void> removeCard(String collectionId, String cardId);
  Future<void> moveCard(String fromId, String toId, String cardId);

  List<CardCollection> getCollectionsForCard(String cardId);
  bool isCardInAnyCollection(String cardId);

  // Persistence: SharedPreferences (JSON encoded list)
}
```

### UI Akışı
```
HomeScreen → "Klasörlerim" bölümü
  → CollectionsScreen (tüm klasörler grid/liste)
    → CollectionDetailScreen (klasör içi kartlar)
      → FlashcardScreen veya CaseStudyScreen ile çalış

FlashcardScreen / CaseStudyScreen
  → Kart üzerinde 📁 ikonu
    → AddToCollectionSheet (mevcut klasörler + "Yeni Oluştur")
```

### Mevcut Bookmark ile Uyum
- Mevcut `isBookmarked` (SM2CardData) korunur → "Favoriler" özel bir sabit klasör olarak gösterilir
- Yeni klasör sistemi ek bir katman olarak çalışır, SM2 verisine dokunmaz
- Migration: Mevcut bookmark'lı kartlar otomatik olarak "⭐ Favoriler" klasörüne eklenir

---

## Özellik 3: Kaydırılabilir Spot / Hap Bilgiler Ekranı

### Amaç
TUS'ta sıkça sorulan "high-yield" bilgileri Instagram Reels/TikTok tarzı dikey kaydırmalı kartlar şeklinde sunmak. Mevcut JSON'lardaki `tus_spots` alanı doğrudan kullanılır.

### Yeni Dosyalar

| Dosya | Konum | Açıklama |
|-------|-------|----------|
| `spots_screen.dart` | `lib/screens/` | Tam ekran dikey kaydırmalı spot kartları |
| `spot_card_widget.dart` | `lib/widgets/` | Tek bir spot kartı widget'ı (glassmorphism) |

### Değiştirilecek Dosyalar

| Dosya | Değişiklik |
|-------|-----------|
| `lib/screens/home_screen.dart` | "Spot Bilgiler" hızlı erişim butonu eklenir |
| `lib/models/topic_model.dart` | `tusSpots` alanı zaten mevcut — ek alan gerekmez |

### Mimari Detay

```
┌─────────────────────────────────────┐
│  SpotsScreen                        │
│  ┌─────────────────────────────┐    │
│  │  PageView.builder (vertical) │   │
│  │  ┌───────────────────────┐   │   │
│  │  │  SpotCardWidget       │   │   │
│  │  │  ┌─────────────────┐  │   │   │
│  │  │  │ 🔬 Konu Başlığı │  │   │   │
│  │  │  ├─────────────────┤  │   │   │
│  │  │  │ Spot bilgi metni│  │   │   │
│  │  │  │ (büyük, bold)   │  │   │   │
│  │  │  ├─────────────────┤  │   │   │
│  │  │  │ Kaynak: Konu adı│  │   │   │
│  │  │  │ ❤️ 📁 Paylaş    │  │   │   │
│  │  │  └─────────────────┘  │   │   │
│  │  └───────────────────────┘   │   │
│  │          ↕ Swipe              │   │
│  │  ┌───────────────────────┐   │   │
│  │  │  Sonraki Spot...      │   │   │
│  │  └───────────────────────┘   │   │
│  └─────────────────────────────┘    │
│  [Filtre: Tümü | Mikro | Pato | An]│
└─────────────────────────────────────┘
```

### Veri Toplama
```dart
// DataService'ten mevcut topic'lerin tusSpots'larını toplama
List<SpotItem> spots = [];
for (final topic in allTopics) {
  for (final spot in topic.tusSpots) {
    spots.add(SpotItem(
      text: spot,
      subject: topic.subject,
      chapter: topic.chapter,
      topicName: topic.topic,
    ));
  }
}
spots.shuffle(); // Rastgele sıralama
```

### SpotItem (Lightweight — ayrı model dosyası gerekmez)
```dart
// spots_screen.dart içinde tanımlanır
class SpotItem {
  final String text;
  final String subject;
  final String chapter;
  final String topicName;
}
```

### UI Özellikleri
- **PageView** ile tam ekran dikey kaydırma (snap physics)
- **Konu filtresi**: Üstte chip bar (Tümü, Mikrobiyoloji, Patoloji, Anatomi)
- **Glassmorphism kart**: Yarı-şeffaf, gradient arka plan
- **Büyük tipografi**: Spot bilgi metni 20-24sp, bold
- **Alt aksiyonlar**: Bookmark, Klasöre Ekle, Paylaş (clipboard copy)
- **Progress indicator**: X / toplam spot sayısı
- **Shuffle butonu**: Spot'ları karıştır

---

## Özellik 4: Gerçek Süreli Deneme Sınavı Modülü

### Amaç
TUS sınavını simüle eden zamanlı, tam kapsamlı deneme sınavı. Gerçek sınav koşullarında (süre baskısı, konu dağılımı, sonuç analizi) pratik yapma imkanı.

### Yeni Dosyalar

| Dosya | Konum | Açıklama |
|-------|-------|----------|
| `mock_exam_model.dart` | `lib/models/` | Sınav, sınav sonucu, sınav ayarları modelleri |
| `mock_exam_service.dart` | `lib/services/` | Sınav oluşturma, zamanlayıcı, sonuç hesaplama |
| `mock_exam_setup_screen.dart` | `lib/screens/` | Sınav başlatma ayarları ekranı |
| `mock_exam_screen.dart` | `lib/screens/` | Sınav çözme ekranı (zamanlı) |
| `mock_exam_result_screen.dart` | `lib/screens/` | Sınav sonuç analizi ekranı |
| `exam_timer_widget.dart` | `lib/widgets/` | Geri sayım zamanlayıcı widget'ı |
| `exam_question_nav.dart` | `lib/widgets/` | Soru navigasyon şeridi (1-2-3...N) |

### Değiştirilecek Dosyalar

| Dosya | Değişiklik |
|-------|-----------|
| `lib/screens/home_screen.dart` | "Deneme Sınavı" kartı / butonu eklenir |
| `lib/services/progress_service.dart` | `recordExamResult()` metodu eklenir |
| `lib/models/progress_model.dart` | `examHistory` alanı eklenir |

### Model Tasarımı

```dart
/// Sınav konfigürasyonu
class MockExamConfig {
  final int questionCount;          // 10, 20, 50, 100
  final int timeLimitMinutes;       // questionCount * 1.5 dk (varsayılan)
  final List<String> subjectIds;    // Hangi konulardan
  final bool shuffleQuestions;      // Soru sırasını karıştır
  final bool showInstantFeedback;   // Her soruda anında geri bildirim
}

/// Tek bir sınav sorusu (ClinicalCase wrapper)
class ExamQuestion {
  final ClinicalCase clinicalCase;
  final String subject;             // Hangi konudan geldi
  String? selectedAnswer;           // Kullanıcının cevabı
  bool get isAnswered => selectedAnswer != null;
  bool get isCorrect => selectedAnswer == clinicalCase.correctAnswer;
}

/// Tamamlanmış sınav kaydı
class MockExamResult {
  final String id;                  // UUID
  final DateTime date;
  final int totalQuestions;
  final int correctAnswers;
  final int unanswered;
  final int timeTakenSeconds;
  final int timeLimitSeconds;
  final Map<String, SubjectScore> subjectBreakdown; // Konu bazlı analiz
  final List<ExamQuestion> questions;  // Detaylı soru listesi

  double get accuracy => correctAnswers / totalQuestions;
  double get netScore => correctAnswers - (wrongAnswers * 0.25); // TUS net hesabı
}

/// Konu bazlı performans
class SubjectScore {
  final String subjectId;
  final int total;
  final int correct;
  double get accuracy => correct / total;
}
```

### Service Tasarımı

```dart
class MockExamService extends ChangeNotifier {
  // Singleton pattern

  // ── Sınav Oluşturma ──
  MockExamConfig? _config;
  List<ExamQuestion> _questions = [];

  Future<void> generateExam(MockExamConfig config);
  // → DataService'ten klinik vakaları toplar
  // → Konu dağılımına göre orantılı seçim yapar
  // → Karıştırır, ExamQuestion listesi oluşturur

  // ── Sınav Zamanlayıcı ──
  Timer? _timer;
  int _remainingSeconds;
  bool _isRunning;

  void startTimer();
  void pauseTimer();
  void resumeTimer();
  String get formattedTime; // "24:59"
  double get timeProgress;  // 0.0 - 1.0

  // ── Soru Navigasyonu ──
  int _currentIndex;
  void goToQuestion(int index);
  void nextQuestion();
  void previousQuestion();
  void answerQuestion(int index, String answer);
  void toggleFlag(int index); // Soruyu işaretle

  // ── Sınav Tamamlama ──
  MockExamResult finishExam();
  // → Timer durdur, sonuç hesapla, kaydet

  // ── Geçmiş ──
  List<MockExamResult> getExamHistory();
  Future<void> saveExamResult(MockExamResult result);
  // Persistence: SharedPreferences (JSON encoded)
}
```

### UI Akışı

```
HomeScreen → "Deneme Sınavı Başlat" butonu
  │
  ▼
MockExamSetupScreen
  ├── Soru sayısı seçimi: [10] [20] [50] [100]
  ├── Konu seçimi: ☑ Mikrobiyoloji ☑ Patoloji ☑ Anatomi
  ├── Süre ayarı: Otomatik (soru×1.5dk) veya Manuel
  ├── Anında geri bildirim: Açık/Kapalı toggle
  └── [SINAVI BAŞLAT] butonu
        │
        ▼
MockExamScreen
  ┌─────────────────────────────────────────┐
  │ ⏱ 42:15  │  Soru 7/50  │  🚩 İşaretle │
  ├─────────────────────────────────────────┤
  │                                         │
  │  Klinik vaka metni...                   │
  │                                         │
  │  ○ A) Seçenek 1                         │
  │  ● B) Seçenek 2  ← seçildi             │
  │  ○ C) Seçenek 3                         │
  │  ○ D) Seçenek 4                         │
  │  ○ E) Seçenek 5                         │
  │                                         │
  ├─────────────────────────────────────────┤
  │ [← Önceki]  1 2 3 ④ 5 6 ⑦ ...  [→]    │
  │ Soru nav şeridi (dolu=cevaplı, ●=aktif) │
  ├─────────────────────────────────────────┤
  │         [SINAVI BİTİR]                  │
  └─────────────────────────────────────────┘
        │
        ▼
MockExamResultScreen
  ┌─────────────────────────────────────────┐
  │        🏆 SINAV SONUCU                  │
  │                                         │
  │  Net: 38.5 / 50    Doğru: 42           │
  │  Yanlış: 6   Boş: 2   Süre: 47:32     │
  │                                         │
  │  ── Konu Bazlı Analiz ──               │
  │  Mikrobiyoloji  ████████░░  82%         │
  │  Patoloji       ██████░░░░  65%         │
  │  Anatomi        ███████░░░  73%         │
  │                                         │
  │  ── Zayıf Alanlar ──                   │
  │  ⚠ Patoloji - En düşük performans      │
  │                                         │
  │  [Yanlışları İncele] [Yeni Sınav] [Ana] │
  └─────────────────────────────────────────┘
```

### TUS Net Hesaplama
```
Net = Doğru - (Yanlış × 0.25)
// Boş sorular cezasız
// TUS gerçek hesabıyla aynı formül
```

---

## Özellik 5: Liderlik Tablosu / Gamification

### Amaç
Kullanıcıların haftalık/aylık çalışma performanslarını karşılaştırabilecekleri anonim sıralama tablosu. Motivasyonu artıran rozet ve seviye sistemi.

### Yeni Dosyalar

| Dosya | Konum | Açıklama |
|-------|-------|----------|
| `leaderboard_model.dart` | `lib/models/` | Sıralama verisi, rozet, seviye modelleri |
| `leaderboard_service.dart` | `lib/services/` | Firestore okuma/yazma, skor hesaplama |
| `leaderboard_screen.dart` | `lib/screens/` | Sıralama tablosu ekranı |
| `badges_sheet.dart` | `lib/widgets/` | Rozet koleksiyonu bottom sheet |
| `level_progress_widget.dart` | `lib/widgets/` | Seviye ilerleme çubuğu |

### Değiştirilecek Dosyalar

| Dosya | Değişiklik |
|-------|-----------|
| `lib/screens/home_screen.dart` | Seviye göstergesi + liderlik tablosu butonu |
| `lib/screens/analytics_screen.dart` | Rozet bölümü eklenir |
| `lib/services/progress_service.dart` | Haftalık skor hesaplama, Firestore push |

### Model Tasarımı

```dart
/// Sıralama tablosundaki tek giriş
class LeaderboardEntry {
  final String odaId;             // Anonim kullanıcı ID
  final String displayName;      // "KlinDoktor" veya anonim
  final String emoji;            // Profil emojisi
  final int weeklyScore;         // Haftalık toplam puan
  final int streak;              // Aktif streak
  final int level;               // Hesaplanmış seviye
  final String targetBranch;     // TUS branşı
}

/// Rozet tanımı
class Badge {
  final String id;
  final String name;             // "İlk Adım"
  final String description;     // "İlk 10 kartı tamamla"
  final String emoji;           // "🎯"
  final bool isUnlocked;
  final DateTime? unlockedAt;
}

/// Seviye sistemi
class UserLevel {
  final int level;               // 1-100
  final String title;            // "Intern", "Asistan", "Uzman", "Profesör"
  final int currentXP;
  final int requiredXP;          // Sonraki seviye için
  double get progress => currentXP / requiredXP;
}
```

### Skor Hesaplama Formülü
```
Haftalık Skor =
  (flashcard_çalışılan × 1) +           // Her kart 1 puan
  (doğru_cevap × 3) +                   // Her doğru vaka 3 puan
  (streak_günü × 10) +                  // Her streak günü 10 puan
  (focus_dakika × 0.5) +                // Her focus dakikası 0.5 puan
  (deneme_sınavı_net × 5)               // Her net 5 puan
```

### XP / Seviye Sistemi
```
Seviye 1-10:   "Intern"     (her seviye 100 XP)
Seviye 11-25:  "Asistan"    (her seviye 200 XP)
Seviye 26-50:  "Uzman"      (her seviye 350 XP)
Seviye 51-100: "Profesör"   (her seviye 500 XP)

XP Kaynakları:
- Flashcard çalış: +2 XP
- Vaka doğru cevapla: +5 XP
- Günlük hedefi tamamla: +25 XP
- 7 gün streak: +100 XP
- Deneme sınavı bitir: +50 XP
- Rozet kazan: +30 XP
```

### Rozet Listesi (Başlangıç Seti)
```
🎯 İlk Adım        — İlk 10 kartı çalış
🔥 Ateş Başladı     — 3 gün üst üste çalış
⚡ Hız Treni        — Bir günde 100 kart çalış
🏆 Sınav Savaşçısı  — İlk deneme sınavını tamamla
🧠 Hafıza Ustası    — 50 kartı "öğrenildi" seviyesine getir
📚 Kitap Kurdu      — 500 toplam kart çalış
🎯 Keskin Nişancı   — Deneme sınavında %80+ doğru
🔥 Yanmaz           — 30 gün streak
💎 Elmas Zihin      — 1000 kartı öğren
🏅 TUS Hazır        — Tüm konulardan en az 100 kart çalış
```

### Firestore Yapısı
```
leaderboard/
  └── weekly/
      └── {week_id}/           // "2026-W13"
          └── {user_id}: {
              displayName: "KlinDoktor",
              emoji: "🧑‍⚕️",
              weeklyScore: 1250,
              streak: 14,
              level: 23,
              targetBranch: "Kardiyoloji",
              updatedAt: Timestamp
          }

users/
  └── {user_id}/
      └── badges: [
          { id: "first_steps", unlockedAt: Timestamp },
          ...
      ]
      └── stats: {
          totalXP: 4500,
          level: 23,
          lifetimeFlashcards: 2340,
          ...
      }
```

### UI Tasarımı

```
LeaderboardScreen
  ┌─────────────────────────────────────────┐
  │  🏆 Liderlik Tablosu                   │
  │  [Bu Hafta] [Bu Ay] [Tüm Zamanlar]     │
  ├─────────────────────────────────────────┤
  │  🥇 1. DrAhmet      1,850 puan  Lv.32  │
  │  🥈 2. TıpÖğrenci   1,720 puan  Lv.28  │
  │  🥉 3. KlinDoktor   1,650 puan  Lv.23  │
  │     4. MedStudent    1,480 puan  Lv.21  │
  │     5. TUSHazırlık   1,350 puan  Lv.19  │
  │     ...                                 │
  ├─────────────────────────────────────────┤
  │  ── Senin Sıran ──                     │
  │  📍 3. sıradasın   1,650 puan          │
  │  ⬆ Geçen haftaya göre +2 sıra          │
  ├─────────────────────────────────────────┤
  │  ── Rozetlerin ──                      │
  │  🎯 ⚡ 🏆 🧠  (4/10 rozet)             │
  │  [Tümünü Gör →]                        │
  └─────────────────────────────────────────┘
```

---

## Toplam Dosya Özeti

### Yeni Dosyalar (17 adet)

| # | Dosya | Tür |
|---|-------|-----|
| 1 | `lib/widgets/ai_chat_sheet.dart` | Widget |
| 2 | `lib/models/collection_model.dart` | Model |
| 3 | `lib/services/collection_service.dart` | Service |
| 4 | `lib/screens/collections_screen.dart` | Screen |
| 5 | `lib/screens/collection_detail_screen.dart` | Screen |
| 6 | `lib/widgets/add_to_collection_sheet.dart` | Widget |
| 7 | `lib/screens/spots_screen.dart` | Screen |
| 8 | `lib/widgets/spot_card_widget.dart` | Widget |
| 9 | `lib/models/mock_exam_model.dart` | Model |
| 10 | `lib/services/mock_exam_service.dart` | Service |
| 11 | `lib/screens/mock_exam_setup_screen.dart` | Screen |
| 12 | `lib/screens/mock_exam_screen.dart` | Screen |
| 13 | `lib/screens/mock_exam_result_screen.dart` | Screen |
| 14 | `lib/widgets/exam_timer_widget.dart` | Widget |
| 15 | `lib/models/leaderboard_model.dart` | Model |
| 16 | `lib/services/leaderboard_service.dart` | Service |
| 17 | `lib/screens/leaderboard_screen.dart` | Screen |

### Değiştirilecek Mevcut Dosyalar (7 adet)

| Dosya | Özellikler |
|-------|-----------|
| `lib/services/ai_service.dart` | #1 (contextual AI) |
| `lib/screens/flashcard_screen.dart` | #1, #2 |
| `lib/screens/case_study_screen.dart` | #1, #2 |
| `lib/screens/home_screen.dart` | #2, #3, #4, #5 |
| `lib/services/progress_service.dart` | #4, #5 |
| `lib/models/progress_model.dart` | #4, #5 |
| `lib/screens/analytics_screen.dart` | #5 |

---

## Bağımlılık Grafiği

```
Özellik 1 (AI Asistan)     → Bağımsız (mevcut AIService üzerine)
Özellik 2 (Klasörler)      → Bağımsız (yeni servis)
Özellik 3 (Spot Bilgiler)  → Bağımsız (mevcut veri)
Özellik 4 (Deneme Sınavı)  → Bağımsız (yeni modül)
Özellik 5 (Leaderboard)    → Özellik 4'e bağlı (sınav skoru dahil)
                           → Firebase Firestore altyapısına bağlı (zaten mevcut)
```

---

## Zaman Tahmini ve Risk Analizi

| Özellik | Karmaşıklık | Risk |
|---------|-------------|------|
| 1. AI Asistan | Düşük | API maliyeti (token kullanımı) |
| 2. Klasörler | Orta | SharedPrefs boyut limiti (çok fazla kart) |
| 3. Spot Bilgiler | Düşük | Yeterli tusSpots verisi olmalı |
| 4. Deneme Sınavı | Yüksek | Timer edge case'leri, app lifecycle |
| 5. Leaderboard | Yüksek | Firestore kuralları, anonim veri güvenliği |
