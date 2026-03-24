# Advanced SRS & Gamification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 4 seviyeli güven sistemi (Tekrar/Zor/İyi/Kolay) ve streak + haftalık aktivite takibini Flutter uygulamasına eklemek.

**Architecture:** sm2_model.dart'taki computeNext 4 kalite seviyesini destekleyecek şekilde güncellendi (✅ tamamlandı). FlashcardScreen'e cevap yüzünde görünen 4 renkli derecelendirme butonu eklenecek; butonlar CardSwiperController üzerinden programatik swipe tetikleyecek. HomeScreen'e streak banner'ı ve weeklyStats verisini kullanan 7 günlük mini aktivite grafiği eklenecek.

**Tech Stack:** Flutter 3.41, flutter_card_swiper, flutter_animate, SharedPreferences, AppTheme glassmorphism

---

## Dosya Haritası

| Dosya | Durum | Ne değişecek |
|---|---|---|
| `lib/models/sm2_model.dart` | ✅ Tamamlandı | computeNext 4 seviyeli yapıldı |
| `lib/screens/flashcard_screen.dart` | 🔧 Değişecek | _pendingQuality, _rateAndSwipe, 4 buton, _FlashCard.onRate callback |
| `lib/screens/home_screen.dart` | 🔧 Değişecek | Streak banner, haftalık aktivite grafiği |

---

## Task 1: FlashcardScreen — Pending Quality Mekanizması

**Files:**
- Modify: `lib/screens/flashcard_screen.dart` (state alanı + yöntem + onSwipe güncellemesi)

- [ ] **Step 1:** `_FlashcardScreenState`'e `_pendingQuality` alanı ekle

```dart
// _dragPctY = 0; satırının altına:
int? _pendingQuality;
```

- [ ] **Step 2:** `_rateAndSwipe` metodunu `_applyMode`'un altına ekle

```dart
/// Butondan kalite seçildiğinde çağrılır; kartı programatik swipe ile ilerletir.
Future<void> _rateAndSwipe(int quality) async {
  _pendingQuality = quality;
  _swiperController.swipe(
    quality >= 3 ? CardSwiperDirection.top : CardSwiperDirection.bottom,
  );
}
```

- [ ] **Step 3:** `onSwipe` içindeki quality satırını güncelle

Eski:
```dart
final quality = effectiveDir == CardSwiperDirection.top ? 4 : 1;
```
Yeni:
```dart
final quality = _pendingQuality ?? (effectiveDir == CardSwiperDirection.top ? 3 : 1);
_pendingQuality = null;
```

- [ ] **Step 4:** `flutter analyze lib/screens/flashcard_screen.dart` çalıştır, hata yoksa devam et.

- [ ] **Step 5:** Commit

```bash
git add lib/screens/flashcard_screen.dart
git commit -m "feat(srs): add pending quality mechanism for 4-level grading"
```

---

## Task 2: FlashcardScreen — _FlashCard'a onRate Callback + 4 Buton

**Files:**
- Modify: `lib/screens/flashcard_screen.dart` (_FlashCard widget + _buildBack + _RatingButton)

- [ ] **Step 1:** `_FlashCard` widget'ına `onRate` alanı ekle

```dart
class _FlashCard extends StatefulWidget {
  final Flashcard card;
  final SpacedRepetitionService srService;
  final void Function(int quality)? onRate;   // YENİ

  const _FlashCard({
    super.key,
    required this.card,
    required this.srService,
    this.onRate,                               // YENİ
  });
```

- [ ] **Step 2:** `cardBuilder` içinde `onRate` callback'ini geç

```dart
_FlashCard(
  key: ValueKey(_cards[index].id),
  card: _cards[index],
  srService: _srService,
  onRate: index == _currentIndex ? _rateAndSwipe : null,  // YENİ
),
```

- [ ] **Step 3:** `_buildBack()` altına rating buton satırı ekle (cevap ipucu metninin üstüne)

```dart
// "Swipe yukarı: İyi  ·  Aşağı: Tekrar" satırının üstüne:
if (widget.onRate != null) ...[
  const Spacer(),
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _RatingButton(label: 'Tekrar', color: const Color(0xFFFF453A), onTap: () => widget.onRate!(1)),
      _RatingButton(label: 'Zor',    color: const Color(0xFFFF9F0A), onTap: () => widget.onRate!(2)),
      _RatingButton(label: 'İyi',    color: const Color(0xFF30D158), onTap: () => widget.onRate!(3)),
      _RatingButton(label: 'Kolay',  color: const Color(0xFF0A84FF), onTap: () => widget.onRate!(4)),
    ],
  ),
  const SizedBox(height: 8),
],
```

- [ ] **Step 4:** Dosyanın en altına `_RatingButton` widget'ı ekle

```dart
class _RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.50), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5:** Swipe etiketini güncelle (back card hint metni)

Eski: `'Swipe yukarı: Bildim  ·  Aşağı: Bilmedim'`
Yeni: `'↑ İyi  ·  ↓ Tekrar  ·  ← Geri Al'`

- [ ] **Step 6:** Gesture hint'lerini güncelle

```dart
// _buildGestureHints() içinde:
_HintChip(icon: Icons.arrow_downward_rounded, label: 'Tekrar', ...),  // Bilmedim → Tekrar
_HintChip(icon: Icons.arrow_upward_rounded,   label: 'İyi',    ...),  // Bildim → İyi
```

- [ ] **Step 7:** `flutter analyze` → hata yok → commit

```bash
git add lib/screens/flashcard_screen.dart
git commit -m "feat(srs): add 4-level rating buttons (Tekrar/Zor/İyi/Kolay) to flashcard"
```

---

## Task 3: HomeScreen — Streak Banner

**Files:**
- Modify: `lib/screens/home_screen.dart` (_buildStreakBanner + yerleştirme)

- [ ] **Step 1:** `_buildStreakBanner(bool isDark)` metodunu ekle

```dart
Widget _buildStreakBanner(bool isDark) {
  final streak = _progress.currentStreak;
  if (streak == 0) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6B00).withValues(alpha: isDark ? 0.20 : 0.12),
              const Color(0xFFFF3B30).withValues(alpha: isDark ? 0.10 : 0.06),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Text('🔥', style: const TextStyle(fontSize: 22))
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2000.ms, color: const Color(0xFFFFCC00)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak Gündür Aralıksız!',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Serini korumaya devam et 💪',
                    style: GoogleFonts.inter(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.4)),
              ),
              child: Text(
                '🔥 $streak',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF6B00),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ).animate().fadeIn(duration: 600.ms, delay: 150.ms).slideX(begin: -0.05, end: 0);
}
```

- [ ] **Step 2:** `_buildHeroCard(isDark)` çağrısından önce banner'ı ekle

```dart
// Column children içinde _buildHeroCard satırının üstüne:
_buildStreakBanner(isDark),
```

- [ ] **Step 3:** `flutter analyze` → commit

```bash
git add lib/screens/home_screen.dart
git commit -m "feat(gamification): add streak banner to home screen"
```

---

## Task 4: HomeScreen — Haftalık Aktivite Grafiği

**Files:**
- Modify: `lib/screens/home_screen.dart` (_buildWeeklyActivity + _buildHeroCard'a ekleme)

- [ ] **Step 1:** `_buildWeeklyActivity(bool isDark)` metodunu ekle

```dart
Widget _buildWeeklyActivity(bool isDark) {
  final today = DateTime.now();
  final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
  final dayNames = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];

  // Haftanın max değeri (normalizasyon için)
  int maxVal = 1;
  for (final d in days) {
    final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    final val = _progress.weeklyStats[key] ?? 0;
    if (val > maxVal) maxVal = val;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Son 7 Gün',
        style: GoogleFonts.inter(
          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final d = days[i];
          final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
          final count = _progress.weeklyStats[key] ?? 0;
          final ratio = count / maxVal;
          final isToday = d.day == today.day && d.month == today.month;
          final color = isToday ? AppTheme.cyan : AppTheme.neonPurple;

          return Column(
            children: [
              Container(
                width: 28,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  width: 28,
                  height: count == 0 ? 4 : (ratio * 48).clamp(4, 48),
                  decoration: BoxDecoration(
                    color: count == 0
                        ? color.withValues(alpha: 0.12)
                        : color.withValues(alpha: isDark ? 0.80 : 0.70),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: count > 0
                        ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8)]
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dayNames[d.weekday - 1],
                style: GoogleFonts.inter(
                  color: isToday
                      ? AppTheme.cyan
                      : (isDark ? AppTheme.textMuted : AppTheme.lightTextSecondary),
                  fontSize: 9,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    ],
  );
}
```

- [ ] **Step 2:** `_buildHeroCard` içindeki stat Row'unun altına haftalık grafiği ekle

```dart
// Sınava Kalan / Doğruluk Row'undan sonra:
const SizedBox(height: 20),
_buildWeeklyActivity(isDark),
```

- [ ] **Step 3:** `flutter analyze` → hata yok → commit

```bash
git add lib/screens/home_screen.dart
git commit -m "feat(gamification): add 7-day activity chart to home screen"
```

---

## Task 5: Son Kontrol & Hot Restart

- [ ] **Step 1:** `flutter analyze lib/` çalıştır — error olmamalı (sadece info/warning kabul)
- [ ] **Step 2:** Chrome'da **R** (hot restart) ile uygulamayı yenile
- [ ] **Step 3:** Manuel test:
  - Bir kart çevir → 4 buton görünüyor mu?
  - Tekrar/Zor/İyi/Kolay'a bas → kart ilerliyor mu?
  - Yukarı swipe → kart ilerliyor mu (İyi olarak)?
  - Aşağı swipe → kart ilerliyor mu (Tekrar olarak)?
  - Ana sayfada streak > 0 ise banner görünüyor mu?
  - Haftalık çubuklar doğru günleri gösteriyor mu?
- [ ] **Step 4:** Final commit

```bash
git add -A
git commit -m "feat: advanced SRS 4-level grading + streak banner + weekly activity chart"
```
