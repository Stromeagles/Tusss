# AsisTus — Overnight Sprint Walkthrough
*Tarih: 2026-03-24*

## Tamamlanan Görevler

### GÖREV 1: 3-Way Reorganizasyon (Doğrular / Yanlışlar / Favoriler)

**Durum: Zaten Uygulanmış — Doğrulama Yapıldı**

Analiz sonucu:
- `lib/screens/flashcard_screen.dart`: `_ModeToggle` widget'i sıralamayı `learnedOnly → failedOnly → pocketOnly` olarak döngü yapıyor. Etiketler: "Doğrular" (check_circle), "Yanlışlar" (cancel), "Favoriler" (bookmark) — sıra doğru.
- `lib/screens/case_study_screen.dart`: `PopupMenuButton`'da sıra `learnedOnly ("Doğrular") → failedOnly ("Yanlışlar") → pocketOnly ("Favoriler")` — sıra doğru.
- Swipe ipuçları `_buildGestureHints()` içinde: "Doğru" (yukarı ok) ve "Yanlış" (aşağı ok) — doğru.
- Sol swipe (geri al): `onSwipe` callback içinde `CardSwiperDirection.left` için `return false` ile etkisizleştirilmiş — doğru.

Değiştirilen dosyalar: Yok (zaten doğru).

---

### GÖREV 2: Firebase Bulut Senkronizasyonu

**Durum: Zaten Uygulanmış — Doğrulama Yapıldı**

Analiz sonucu:
- `lib/services/progress_service.dart`: `_firestoreDoc` getter `users/{uid}/content/study_data` yoluna yazar. `loadProgress()` Firestore'dan veri çekip SharedPreferences'a merge ediyor. Tüm write metodları (`markFlashcardSeen`, `recordCaseAnswer`, `setDailyGoal` vb.) `_backupToFirestore()` çağırıyor.
- `lib/services/spaced_repetition_service.dart`: `_firestoreDoc` getter `users/{uid}/content/srs_data` yoluna yazar. `getAllData()` Firestore'dan SRS verisi çekiyor. Her rating güncellemesi Firestore'a yedekleniyor.

Değiştirilen dosyalar: Yok (zaten doğru).

---

### GÖREV 3: UI/UX Temizliği + 20 Limit

**Durum: Kısmen Zaten Uygulanmış + Focus Screen Güncellendi**

Analiz ve değişiklikler:
- `web/index.html`: Splash ekranında SVG yoktu zaten — temiz arka plan `#0F172A` rengiyle korudu.
- `lib/services/premium_service.dart`: `dailyFreeFlashcardLimit = 20` ve `dailyFreeCaseLimit = 20` zaten tanımlı.
- `lib/widgets/daily_goal_widget.dart`: Hardcoded "50" yok; `dailyGoal` parametresi dışarıdan geliyor. `PremiumService.dailyFreeFlashcardLimit` ile karşılaştırarak "Günlük Limit" veya "Günlük Hedef" gösteriyor.

**Değiştirilen dosya:** `lib/screens/focus_screen.dart`
- Ücretsiz kullanıcılar için `freePresets = [10, 15, 25]` → `freePresets = [25]` olarak daraltıldı (GÖREV 4 gereklilikleriyle uyumlu).

---

### GÖREV 4: Premium Kilitleme + Focus Lab Yenileme

**Durum: Büyük Ölçüde Zaten Uygulanmış + freePresets Düzeltildi**

Analiz sonucu:
- `lib/widgets/add_to_collection_sheet.dart`: `_isPremium` kontrolü var. "Yeni Klasör Oluştur" butonu premium değilse `_showPremiumGate()` çağırıyor, klasör tile'a tıklamak da premium gate tetikliyor — doğru.
- `lib/screens/focus_screen.dart`: Gradient arka plan `#020810 → #05101E → #0A1628` (koyu gece tonları). Timer etrafında `_BreathingBlob` ve `AnimatedBuilder` ile neon breathing glow efekti aktif.

**Değiştirilen dosya:** `lib/screens/focus_screen.dart`
- `freePresets = [25]`: Sadece 25 dk seçeneği ücretsiz kullanıcılara açık.
- `freeBreaks = [5]`: Mola süresi zaten 5dk ile kısıtlıydı.
- `freeSounds = {FocusSound.none, FocusSound.yagmur}`: Sessiz + Yağmur serbest, gerisine kilit ikonu gösteriliyor — doğru.

---

### GÖREV 5: Robot AI Koç Doğrulama

**Durum: Zaten Uygulanmış — Doğrulama Yapıldı**

Analiz sonucu:
- `lib/screens/home_screen.dart` satır ~299: `Icons.psychology_rounded` (cyan) ikonu header'da yerleşik.
- `onTap: _showAiInsightSheet` ile bağlı.
- `_showAiInsightSheet()`: SM-2 verisinden `lastQuality == 1` olanları branş ve konu bazında grupluyor, top 3 hatalı konuyu tespit ediyor, `AiInsightSheet` widget'ını açıyor.
- `AiInsightSheet`: `progress`, `mistakeCounts`, `topMistakeTopics`, `targetBranch` parametrelerini alıyor.

**Ek temizlik:** Kullanılmayan `_openAiInsightSheet(bool isDark)` metodu silindi (`home_screen.dart`).

Değiştirilen dosyalar: `lib/screens/home_screen.dart` (unused method kaldırıldı).

---

## Düzeltilen Sorunlar

| Dosya | Değişiklik | Açıklama |
|---|---|---|
| `lib/screens/focus_screen.dart` | `freePresets = [25]` | Ücretsiz kullanıcılar yalnızca 25dk seçebilir |
| `lib/screens/home_screen.dart` | `_openAiInsightSheet` silindi | Kullanılmayan duplicate metod temizlendi |

---

## Flutter Analyze Sonucu

`flutter analyze` çıktısı: **39 info, 0 warning, 0 error**

Tüm sorunlar `prefer_const_constructors` ve `unnecessary_import` seviyesinde — işlevselliği etkilemiyor.

---

## Dikkat Edilmesi Gerekenler

### Açık Kalan İşler
1. **Login ekranı görseli**: Handoff notunda "doktor görseline dön" deniyor — `assets/icon/app_icon.png` (90x90) kullanılıyor. Login ekranındaki görsel değişikliği yapılmadı; login tasarımı son commit'lerde yeniden yapılmıştı, müdahale gerekip gerekmediği netleştirilmeli.
2. **Mikrobiyoloji "Profesör" stili içerik**: İçerik üretim görevi — JSON dosyaları henüz oluşturulmadı (`pending_content_tasks.md`'de kayıtlı).
3. **App Store / Play Store butonları web'de**: `kIsWeb` kontrolü ile görünür yapılması `web_landing_screen.dart`'ta kontrol edilebilir.

### Teknik Notlar
- Firebase projesi: `tusai-2fb30`
- Tüm SRS ve Progress verileri Firestore ile çift yönlü senkronize — tarayıcı geçmişi silinse bile giriş sonrası veriler geri yüklenir.
- Premium reviewer hesapları: `reviewer@tusasistani.app`, `ceylannurettin@outlook.com`.
