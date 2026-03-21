# Daily Goal Focus — Yeni Kart Sınırlandırması Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ana sayfadaki "Yeni" sayacını ve `newOnly` flashcard modunu kullanıcının günlük kart hedefiyle sınırlandır; `newOnly` seans her başlangıçta karıştırılmış olsun.

**Architecture:** `getSummary`'ye opsiyonel `dailyGoal` parametresi eklenir — yalnızca `newCount` değeri budanır. `FlashcardScreen`'e `dailyGoal` alanı eklenir; `_applyMode` içinde `newOnly` dalı karıştırıp listeden `dailyGoal` kadar kart alır. `HomeScreen` her ikisine de `_progress.dailyGoal` iletir.

**Tech Stack:** Flutter 3.41, Dart, `SpacedRepetitionService`, `StudyProgress.dailyGoal` (int)

---

## Dosya Haritası

| Dosya | Değişiklik |
|---|---|
| `lib/services/spaced_repetition_service.dart` | `getSummary` imzasına `{int? dailyGoal}` ekle; `newCount` buda |
| `lib/screens/flashcard_screen.dart` | `FlashcardScreen`'e `int? dailyGoal`; `newOnly` dalına shuffle + take |
| `lib/screens/home_screen.dart` | `getSummary` + `FlashcardScreen` çağrılarına `dailyGoal` ilet |

---

## Task 1: getSummary — dailyGoal Cap

**Files:**
- Modify: `lib/services/spaced_repetition_service.dart`

- [ ] **Step 1:** `getSummary` imzasına named parametreyi ekle ve `newCount`'u buda

Eski imza:
```dart
Future<SrsSummary> getSummary(List<String> allIds) async {
```

Yeni imza:
```dart
Future<SrsSummary> getSummary(List<String> allIds, {int? dailyGoal}) async {
```

`for` döngüsünden SONRA, `return SrsSummary(...)` satırından ÖNCE şu satırı ekle:
```dart
    if (dailyGoal != null && newCount > dailyGoal) newCount = dailyGoal;
```

Tam güncel metod görünümü:
```dart
  Future<SrsSummary> getSummary(List<String> allIds, {int? dailyGoal}) async {
    final all = await getAllData();
    int newCount      = 0;
    int failedCount   = 0;
    int learningCount = 0;
    int pocketCount   = 0;

    for (final id in allIds) {
      final data = all[id];
      if (data == null) {
        newCount++;
      } else if (data.isInPocket) {
        pocketCount++;
      } else if (data.repetitions == 0) {
        failedCount++;
      } else {
        learningCount++;
      }
    }
    if (dailyGoal != null && dailyGoal > 0 && newCount > dailyGoal) newCount = dailyGoal;
    return SrsSummary(
      newCount:      newCount,
      failedCount:   failedCount,
      learningCount: learningCount,
      pocketCount:   pocketCount,
    );
  }
```

- [ ] **Step 2:** Analyze
```
/c/Users/ceyla/Desktop/flutter/bin/flutter analyze lib/services/spaced_repetition_service.dart
```
Working dir: `/c/Users/ceyla/Desktop/tus/tus_app_project/tus_asistani`

Expected: no errors.

- [ ] **Step 3:** Commit
```bash
git add lib/services/spaced_repetition_service.dart
git commit -m "feat(srs): cap getSummary newCount by dailyGoal parameter"
```

---

## Task 2: FlashcardScreen — dailyGoal + shuffle + take

**Files:**
- Modify: `lib/screens/flashcard_screen.dart`

- [ ] **Step 1:** `FlashcardScreen` widget'ına `dailyGoal` alanı ekle

Eski constructor:
```dart
class FlashcardScreen extends StatefulWidget {
  final Topic? topicFilter;
  final String? subjectId;
  final List<String>? subjectIds;
  final FlashcardMode initialMode;

  const FlashcardScreen({
    super.key,
    this.topicFilter,
    this.subjectId,
    this.subjectIds,
    this.initialMode = FlashcardMode.dueOnly,
  });
```

Yeni (sadece `dailyGoal` eklendi):
```dart
class FlashcardScreen extends StatefulWidget {
  final Topic? topicFilter;
  final String? subjectId;
  final List<String>? subjectIds;
  final FlashcardMode initialMode;
  final int? dailyGoal; // newOnly modunda sınır ve karıştırma için

  const FlashcardScreen({
    super.key,
    this.topicFilter,
    this.subjectId,
    this.subjectIds,
    this.initialMode = FlashcardMode.dueOnly,
    this.dailyGoal,
  });
```

- [ ] **Step 2:** `_applyMode`'da `newOnly` dalına shuffle + take ekle

Mevcut `newOnly` dalını bul:
```dart
    } else if (_mode == FlashcardMode.newOnly) {
      // Yeni: Hiç görülmemiş kartlar
      for (var i = 0; i < source.length; i++) {
        if (!allMap.containsKey(source[i].id)) result.add(source[i]);
      }
    }
```

Şununla değiştir:
```dart
    } else if (_mode == FlashcardMode.newOnly) {
      // Yeni: Hiç görülmemiş kartlar
      for (var i = 0; i < source.length; i++) {
        if (!allMap.containsKey(source[i].id)) result.add(source[i]);
      }
      result.shuffle(); // Her seans farklı sıra
      if (widget.dailyGoal != null && widget.dailyGoal! > 0 && result.length > widget.dailyGoal!) {
        result = result.take(widget.dailyGoal!).toList();
      }
    }
```

- [ ] **Step 3:** Analyze
```
/c/Users/ceyla/Desktop/flutter/bin/flutter analyze lib/screens/flashcard_screen.dart
```
Expected: no errors.

- [ ] **Step 4:** Commit
```bash
git add lib/screens/flashcard_screen.dart
git commit -m "feat(flashcard): shuffle + dailyGoal limit in newOnly mode"
```

---

## Task 3: HomeScreen — dailyGoal entegrasyonu

**Files:**
- Modify: `lib/screens/home_screen.dart`

- [ ] **Step 1:** `getSummary` çağrısını güncelle

`_loadData` içinde bu satırı bul:
```dart
      final srsSummary = await SpacedRepetitionService().getSummary(allIds);
```

Şununla değiştir:
```dart
      final srsSummary = await SpacedRepetitionService().getSummary(
        allIds,
        dailyGoal: progress.dailyGoal,
      );
```

Not: Bu satır `Future.wait` sonrasında gelir ve `progress` lokal değişkeni zaten hazır durumdadır.

- [ ] **Step 2:** `_buildHeroCard`'daki `newOnly` navigasyonunu güncelle

Bu satırı bul (hero card'daki 4 sayaç Row içinde):
```dart
                _buildAnkiCounter('Yeni', newCount, AppTheme.cyan, isDark,
                  newCount > 0 ? () => Navigator.push(context, AppRoute.slideUp(
                      const FlashcardScreen(initialMode: FlashcardMode.newOnly))) : null),
```

Şununla değiştir (`const` kaldırılır çünkü `dailyGoal` runtime değeri):
```dart
                _buildAnkiCounter('Yeni', newCount, AppTheme.cyan, isDark,
                  newCount > 0 ? () => Navigator.push(context, AppRoute.slideUp(
                      FlashcardScreen(
                        initialMode: FlashcardMode.newOnly,
                        dailyGoal: _progress.dailyGoal,
                      ))) : null),
```

- [ ] **Step 3:** Analyze
```
/c/Users/ceyla/Desktop/flutter/bin/flutter analyze lib/screens/home_screen.dart
```
Expected: no errors.

- [ ] **Step 4:** Commit
```bash
git add lib/screens/home_screen.dart
git commit -m "feat(home): wire dailyGoal into getSummary and newOnly FlashcardScreen"
```

---

## Task 4: Final Kontrol

- [ ] **Step 1:** Tüm lib analizi
```
/c/Users/ceyla/Desktop/flutter/bin/flutter analyze lib/
```
Expected: 0 errors, 0 warnings. (Pre-existing info hints kabul edilebilir.)

- [ ] **Step 2:** Hot restart (Chrome'da `R`)

- [ ] **Step 3:** Manuel test:
  - Kullanıcının günlük hedefi (örn. 60 kart) ayarlanmışken ana sayfada "Yeni" sayacının ≤ 60 gösterdiğini doğrula
  - "Yeni" sayacına tıkla → FlashcardScreen açıldığında kart sayısının ≤ dailyGoal olduğunu doğrula
  - FlashcardScreen'i kapat, tekrar aç → kartların farklı sırada geldiğini doğrula (shuffle çalışıyor)
  - dailyGoal 0 ise (ya da nil) "Yeni" sayacının tüm yeni kartları gösterdiğini doğrula
