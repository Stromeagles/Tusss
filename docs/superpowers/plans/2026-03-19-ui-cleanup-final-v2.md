# UI Cleanup & Categorization V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 4-kategori SRS sayacı (Yeni/Bilemediklerim/Bildiklerim/Hafıza), hero card doğruluk badgesi QuickAction'a taşınması, daily goal'a puan artışı eklenmesi ve buton etiket temizliği.

**Architecture:** `SrsSummary`'ye `failedCount` alanı eklenir; `getSummary` mantığı yeniden kategorize edilir. `FlashcardScreen`'e `failedOnly` modu eklenir. `HomeScreen`'de hero card 4 sayaca çıkar, doğruluk QuickAction kartına badge olarak taşınır, daily goal'a altın renk puan artışı satırı eklenir, buton etiketi sadeleştirilir. `_QuickActionCard`'a opsiyonel `badge` parametresi eklenir.

**Tech Stack:** Flutter 3.41, AppTheme (neonGold, error, success, cyan), GoogleFonts

---

## Dosya Haritası

| Dosya | Değişiklik |
|---|---|
| `lib/services/spaced_repetition_service.dart` | `SrsSummary.failedCount` + `getSummary` mantığı |
| `lib/screens/flashcard_screen.dart` | `FlashcardMode.failedOnly` enum değeri + `_loadCards` filtresi |
| `lib/screens/home_screen.dart` | 4 sayaç + accuracy badge → QuickAction + puan artışı → DailyGoal + buton etiketi + `_srsSummary` init |

---

## Task 1: SrsSummary — failedCount + getSummary

**Files:**
- Modify: `lib/services/spaced_repetition_service.dart`

Mevcut kategoriler:
- `newCount`: `data == null`
- `learningCount`: `data.repetitions <= 1` (0 ve 1 dahil)
- `pocketCount`: `data.isInPocket`

Yeni kategoriler:
- `newCount`: `data == null` (aynı)
- `failedCount`: `data != null && !data.isInPocket && data.repetitions == 0`
- `learningCount`: `data.repetitions == 1` (sadece 1)
- `pocketCount`: `data.isInPocket` (aynı)

- [ ] **Step 1:** `SrsSummary` sınıfını güncelle — `failedCount` alanı ekle

Eski:
```dart
class SrsSummary {
  final int newCount;
  final int learningCount; // "Bildiklerim" — 1 kez doğru, cepte değil
  final int pocketCount;

  const SrsSummary({
    required this.newCount,
    required this.learningCount,
    required this.pocketCount,
  });

  int get total => newCount + learningCount;
}
```

Yeni:
```dart
class SrsSummary {
  final int newCount;
  final int failedCount;    // Görülmüş ama repetitions == 0 (Tekrar'a düşmüş)
  final int learningCount;  // "Bildiklerim" — tam olarak 1 kez doğru, cepte değil
  final int pocketCount;

  const SrsSummary({
    required this.newCount,
    required this.failedCount,
    required this.learningCount,
    required this.pocketCount,
  });

  int get total => newCount + failedCount + learningCount;
}
```

- [ ] **Step 2:** `getSummary()` metodunu güncelle

Eski:
```dart
  Future<SrsSummary> getSummary(List<String> allIds) async {
    final all = await getAllData();
    int newCount = 0;
    int learningCount = 0; // repetitions == 1 (1 kez doğru, henüz cepte değil)
    int pocketCount = 0;

    for (final id in allIds) {
      final data = all[id];
      if (data == null) {
        newCount++; // hiç görülmemiş
      } else if (data.isInPocket) {
        pocketCount++;
      } else if (data.repetitions <= 1) {
        learningCount++; // 1 kez bildim veya tekrar öğreniyorum → bildiklerim klasörü
      }
    }
    return SrsSummary(
      newCount: newCount,
      learningCount: learningCount,
      pocketCount: pocketCount,
    );
  }
```

Yeni:
```dart
  Future<SrsSummary> getSummary(List<String> allIds) async {
    final all = await getAllData();
    int newCount      = 0;
    int failedCount   = 0; // görülmüş, repetitions == 0 (Tekrar'a düşmüş)
    int learningCount = 0; // tam olarak 1 kez doğru, cepte değil
    int pocketCount   = 0;

    for (final id in allIds) {
      final data = all[id];
      if (data == null) {
        newCount++;                           // hiç görülmemiş
      } else if (data.isInPocket) {
        pocketCount++;                        // Hafıza'da
      } else if (data.repetitions == 0) {
        failedCount++;                        // görülmüş ama sıfırlanmış
      } else if (data.repetitions == 1) {
        learningCount++;                      // 1 kez doğru
      }
    }
    return SrsSummary(
      newCount:      newCount,
      failedCount:   failedCount,
      learningCount: learningCount,
      pocketCount:   pocketCount,
    );
  }
```

- [ ] **Step 3:** `flutter analyze lib/services/spaced_repetition_service.dart` — hata yok

- [ ] **Step 4:** Commit

```bash
git add lib/services/spaced_repetition_service.dart
git commit -m "feat(srs): add failedCount category to SrsSummary"
```

---

## Task 2: FlashcardScreen — failedOnly modu

**Files:**
- Modify: `lib/screens/flashcard_screen.dart`

- [ ] **Step 1:** `FlashcardMode` enum'una `failedOnly` ekle

Eski:
```dart
enum FlashcardMode { all, dueOnly, pocketOnly, newOnly, learnedOnly }
```

Yeni:
```dart
enum FlashcardMode { all, dueOnly, pocketOnly, newOnly, learnedOnly, failedOnly }
```

- [ ] **Step 2:** `_loadCards()` içindeki `failedOnly` filtresi — `SpacedRepetitionService` verisiyle

`_loadCards()` metodunda `FlashcardMode.learnedOnly` bloğundan sonra şu `case`'i ekle.

İlk olarak dosyayı oku ve `_loadCards()` nasıl mode'a göre filtrelediğini gör. Tipik olarak:
```dart
// Mevcut learnedOnly veya benzeri bloğun altına ekle:
} else if (_mode == FlashcardMode.failedOnly) {
  final all = await _srService.getAllData();
  _cards = _allCards.where((fc) {
    final data = all[fc.id];
    return data != null && !data.isInPocket && data.repetitions == 0;
  }).toList();
}
```

Not: Tam ekleme yeri `_loadCards()` içindeki mode koşullarının sonuna. Dosyayı oku ve doğru konumu bul.

- [ ] **Step 3:** `flutter analyze lib/screens/flashcard_screen.dart` — hata yok

- [ ] **Step 4:** Commit

```bash
git add lib/screens/flashcard_screen.dart
git commit -m "feat(srs): add failedOnly flashcard mode"
```

---

## Task 3: HomeScreen — 4 Sayaç + QuickAction Badge + DailyGoal Puan + Buton

**Files:**
- Modify: `lib/screens/home_screen.dart`

### Sub-step A: `_srsSummary` başlangıç değerini güncelle

`_HomeScreenState` field tanımında:

Eski:
```dart
  SrsSummary    _srsSummary = const SrsSummary(newCount: 0, learningCount: 0, pocketCount: 0);
```

Yeni:
```dart
  SrsSummary    _srsSummary = const SrsSummary(newCount: 0, failedCount: 0, learningCount: 0, pocketCount: 0);
```

### Sub-step B: `_buildHeroCard` — 4 sayaca geç + Doğruluk kaldır

**B1 — failedCount değişkenini ekle ve 4 sayacı göster:**

Eski:
```dart
    final newCount      = _srsSummary.newCount;
    final learningCount = _srsSummary.learningCount;
    final pocketCount   = _srsSummary.pocketCount;
```

Yeni:
```dart
    final newCount      = _srsSummary.newCount;
    final failedCount   = _srsSummary.failedCount;
    final learningCount = _srsSummary.learningCount;
    final pocketCount   = _srsSummary.pocketCount;
```

**B2 — 3 sayaçlı Row'u 4 sayaçlı yap:**

Eski:
```dart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAnkiCounter('Yeni', newCount, AppTheme.cyan, isDark,
                  newCount > 0 ? () => Navigator.push(context, AppRoute.slideUp(
                      const FlashcardScreen(initialMode: FlashcardMode.newOnly))) : null),
                _buildAnkiCounter('Bildiklerim', learningCount, AppTheme.error, isDark,
                  learningCount > 0 ? () => Navigator.push(context, AppRoute.slideUp(
                      const FlashcardScreen(initialMode: FlashcardMode.learnedOnly))) : null),
                _buildAnkiCounter('Hafıza', pocketCount, AppTheme.success, isDark,
                  pocketCount > 0 ? () => Navigator.push(context, AppRoute.slideUp(
                      const FlashcardScreen(initialMode: FlashcardMode.pocketOnly))) : null),
              ],
            ),
```

Yeni:
```dart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAnkiCounter('Yeni', newCount, AppTheme.cyan, isDark,
                  newCount > 0 ? () => Navigator.push(context, AppRoute.slideUp(
                      const FlashcardScreen(initialMode: FlashcardMode.newOnly))) : null),
                _buildAnkiCounter('Bilemedim', failedCount, AppTheme.error, isDark,
                  failedCount > 0 ? () => Navigator.push(context, AppRoute.slideUp(
                      const FlashcardScreen(initialMode: FlashcardMode.failedOnly))) : null),
                _buildAnkiCounter('Bildim', learningCount, AppTheme.neonGold, isDark,
                  learningCount > 0 ? () => Navigator.push(context, AppRoute.slideUp(
                      const FlashcardScreen(initialMode: FlashcardMode.learnedOnly))) : null),
                _buildAnkiCounter('Hafıza', pocketCount, AppTheme.success, isDark,
                  pocketCount > 0 ? () => Navigator.push(context, AppRoute.slideUp(
                      const FlashcardScreen(initialMode: FlashcardMode.pocketOnly))) : null),
              ],
            ),
```

**B3 — `_buildAnkiCounter` padding'ini küçült** (4 öğe sığsın diye):

`_buildAnkiCounter` metodunu bul:
```dart
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
```
→ Değiştir:
```dart
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
```

**B4 — Doğruluk `_StatItem`'ını kaldır:**

Hero card stat Row'unda:

Eski:
```dart
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.timer_outlined,
                    label: 'Sınava Kalan',
                    value: '$_daysToExam Gün',
                    color: AppTheme.neonPink,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatItem(
                    icon: Icons.insights_rounded,
                    label: 'Doğruluk',
                    value: '%${_progress.accuracy.toInt()}',
                    color: AppTheme.cyan,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
```

Yeni (sadece "Sınava Kalan" kalır):
```dart
            _StatItem(
              icon: Icons.timer_outlined,
              label: 'Sınava Kalan',
              value: '$_daysToExam Gün',
              color: AppTheme.neonPink,
              isDark: isDark,
            ),
```

**B5 — Büyük buton etiketini sadeleştir:**

Eski:
```dart
                  label: Text(learningCount > 0 ? '$learningCount Bildiğim Kartı Tekrar Et' : 'Yeni Kartlara Başla',
```

Yeni:
```dart
                  label: Text(learningCount > 0 || failedCount > 0 ? 'Kritik Kartları Tekrar Et' : 'Günlük Seansı Başlat',
```

### Sub-step C: `_QuickActionCard` — badge parametresi ekle

`_QuickActionCard` sınıfına `badge` parametresi ekle ve build'e badge overlay koy:

Eski field'lar:
```dart
class _QuickActionCard extends StatelessWidget {
  final String       title;
  final String       subtitle;
  final IconData     icon;
  final Color        color;
  final bool         isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,    required this.subtitle,
    required this.icon,     required this.color,
    required this.isDark,   required this.onTap,
  });
```

Yeni (badge eklendi):
```dart
class _QuickActionCard extends StatelessWidget {
  final String       title;
  final String       subtitle;
  final IconData     icon;
  final Color        color;
  final bool         isDark;
  final VoidCallback onTap;
  final String?      badge; // ör: "🎯 %85"

  const _QuickActionCard({
    required this.title,    required this.subtitle,
    required this.icon,     required this.color,
    required this.isDark,   required this.onTap,
    this.badge,
  });
```

`_QuickActionCard.build()` — Column'u Stack'e sar ve badge ekle:

Eski build'in Column'u:
```dart
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 10, spreadRadius: 1)],
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 14),
              Text(subtitle,
                style: GoogleFonts.inter(color: color.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w700, fontSize: 11)),
            ]),
```

Yeni — Stack ile sarılmış:
```dart
            child: Stack(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.22), shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 10, spreadRadius: 1)],
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 14),
                  Text(subtitle,
                    style: GoogleFonts.inter(color: color.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700, fontSize: 11)),
                ]),
                if (badge != null)
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.40)),
                      ),
                      child: Text(badge!,
                        style: GoogleFonts.inter(
                          color: color, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
```

### Sub-step D: "Klinik Vaka" kartına badge geç

`_buildQuickActions` içinde Klinik Vaka kartına `badge` parametresini ekle:

Eski:
```dart
          Expanded(child: _QuickActionCard(
            title: 'Klinik Vaka', subtitle: 'Random Çözüm',
            icon: Icons.biotech_rounded,
            color: const Color(0xFF79C0FF),
            isDark: isDark, onTap: _navigateToCases,
          )),
```

Yeni:
```dart
          Expanded(child: _QuickActionCard(
            title: 'Klinik Vaka', subtitle: 'Random Çözüm',
            icon: Icons.biotech_rounded,
            color: const Color(0xFF79C0FF),
            isDark: isDark, onTap: _navigateToCases,
            badge: '🎯 %${_progress.accuracy.toInt()}',
          )),
```

### Sub-step E: `_buildDailyGoal` — puan artışı satırı ekle

`_buildDailyGoal` içinde büyük ElevatedButton'dan SONRA puan artışı satırını ekle:

```dart
                const SizedBox(height: 20),
                SizedBox(
                  // ... mevcut ElevatedButton ...
                ),
                // --- BURAYA EKLE ---
                const SizedBox(height: 12),
                _buildDailyScoreLine(isDark),
```

Yeni private metod olarak sınıfa ekle (örn. `_buildDailyGoal`'ın hemen altına):

```dart
  Widget _buildDailyScoreLine(bool isDark) {
    final avgHours = _progress.todayGoalHours;
    final totalPotentialHours = avgHours * _daysToExam;
    final estimatedPoints = (totalPotentialHours / 60).clamp(1.0, 15.0);
    final rangeMin = (estimatedPoints * 0.8).floor();
    final rangeMax = (estimatedPoints * 1.2).ceil();
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'TUS Tahmini Puan Artışı  ',
          style: GoogleFonts.inter(color: subColor, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Text(
          '+$rangeMin – +$rangeMax',
          style: GoogleFonts.inter(
            color: AppTheme.neonGold,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 1:** Sub-step A — `_srsSummary` init güncelle
- [ ] **Step 2:** Sub-step B1-B3 — 4 sayaç + padding
- [ ] **Step 3:** Sub-step B4 — Doğruluk _StatItem kaldır
- [ ] **Step 4:** Sub-step B5 — Buton etiketi sadeleştir
- [ ] **Step 5:** Sub-step C — `_QuickActionCard` badge parametresi + Stack build
- [ ] **Step 6:** Sub-step D — Klinik Vaka'ya badge geç
- [ ] **Step 7:** Sub-step E — `_buildDailyScoreLine` + DailyGoal'a ekle

- [ ] **Step 8:** `flutter analyze lib/screens/home_screen.dart` — hata yok

- [ ] **Step 9:** Commit

```bash
git add lib/screens/home_screen.dart
git commit -m "feat(ui): 4-category counters, accuracy badge, daily score line, clean button label"
```

---

## Task 4: Final Kontrol

- [ ] **Step 1:** `flutter analyze lib/` — error yok

- [ ] **Step 2:** `flutter run -d chrome` veya Chrome'da `R` hot restart

- [ ] **Step 3:** Manuel test:
  - Hero card'da 4 sayaç (Yeni/Bilemedim/Bildim/Hafıza) görünüyor mu?
  - Klinik Vaka kartında sağ üstte "🎯 %X" badgesi var mı?
  - Daily Goal kartında "TUS Tahmini Puan Artışı +X – +Y" neonGold'da mı?
  - Hero card büyük butonu "Kritik Kartları Tekrar Et" veya "Günlük Seansı Başlat" mı diyor?
  - "Doğruluk" _StatItem hero card'dan kalktı mı?
