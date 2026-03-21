# Performance & Fluency Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Uygulamayı daha akıcı ve premium hissettiren 4 performans katmanı eklemek.

**Architecture:** Tüm değişiklikler `home_screen.dart` içinde kalır. Shimmer için `flutter_animate` (zaten mevcut) kullanılır. Scale feedback için `StatefulWidget` değil `TweenAnimationBuilder` + `GestureDetector` pattern tercih edilir. `MaterialPageRoute` çağrıları `AppRoute` ile değiştirilir.

**Tech Stack:** Flutter 3.41, flutter_animate (mevcut), HapticFeedback (flutter/services), AppRoute (lib/utils/transitions.dart)

---

## Dosya Haritası

| Dosya | Değişiklik |
|---|---|
| `lib/screens/home_screen.dart` | Skeleton, Scale/Haptic, BouncingScrollPhysics, RepaintBoundary, MaterialPageRoute→AppRoute |

---

## Task 1: Skeleton Shimmer Loading State

**Files:**
- Modify: `lib/screens/home_screen.dart` — `_buildLoadingState()` + `_ShimmerBox` widget

- [ ] **Step 1:** `_buildLoadingState()` metodunu bul ve içeriğini değiştir

Eski:
```dart
Widget _buildLoadingState() {
  return Center(child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2.5));
}
```

Yeni:
```dart
Widget _buildLoadingState() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 6, 20, 80),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Card skeleton
        _ShimmerBox(height: 220, borderRadius: 30, isDark: isDark),
        const SizedBox(height: 20),
        // Quick Actions skeleton
        Row(children: [
          Expanded(child: _ShimmerBox(height: 90, borderRadius: 22, isDark: isDark)),
          const SizedBox(width: 14),
          Expanded(child: _ShimmerBox(height: 90, borderRadius: 22, isDark: isDark)),
        ]),
        const SizedBox(height: 26),
        // Subject carousel skeleton
        _ShimmerBox(height: 20, width: 140, borderRadius: 8, isDark: isDark),
        const SizedBox(height: 16),
        Row(children: [
          _ShimmerBox(height: 172, width: 158, borderRadius: 22, isDark: isDark),
          const SizedBox(width: 14),
          _ShimmerBox(height: 172, width: 158, borderRadius: 22, isDark: isDark),
        ]),
        const SizedBox(height: 26),
        // Daily Goal skeleton
        _ShimmerBox(height: 160, borderRadius: 24, isDark: isDark),
      ],
    ),
  );
}
```

- [ ] **Step 2:** Dosyanın alt kısmına `_ShimmerBox` widget'ı ekle (diğer private widget'ların yanına)

```dart
class _ShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;
  final bool isDark;

  const _ShimmerBox({
    required this.height,
    required this.borderRadius,
    required this.isDark,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
        );
  }
}
```

- [ ] **Step 3:** `flutter analyze lib/screens/home_screen.dart` — error yok → commit

```bash
git commit -m "feat(perf): skeleton shimmer loading state"
```

---

## Task 2: Scale + Haptic Feedback

**Files:**
- Modify: `lib/screens/home_screen.dart` — `_QuickActionCard`, `_SubjectCarouselCard` + `import 'package:flutter/services.dart'`

- [ ] **Step 1:** Dosyanın en üstüne `services` import'unu ekle (henüz yoksa)

```dart
import 'package:flutter/services.dart';
```

- [ ] **Step 2:** `_QuickActionCard.build()` içinde `GestureDetector`'ı `_PressableCard` wrapper'a çevir

`_QuickActionCard`'ın `build` metodunda şu an `GestureDetector(onTap: onTap, child: ...)` var. Bunu şununla değiştir:

```dart
@override
Widget build(BuildContext context) {
  return _PressableCard(
    onTap: onTap,
    child: ClipRRect(
      // ... mevcut ClipRRect içeriği aynen kalır
    ),
  );
}
```

- [ ] **Step 3:** `_SubjectCarouselCard.build()` içinde de aynısını yap

`GestureDetector(onTap: onTap, child: Container(...))` → `_PressableCard(onTap: onTap, child: Container(...))`

- [ ] **Step 4:** Dosyanın alt kısmına `_PressableCard` widget'ı ekle

```dart
/// Scale 1.0→0.97 press animasyonu + HapticFeedback
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableCard({required this.child, this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
```

- [ ] **Step 5:** `flutter analyze` → error yok → commit

```bash
git commit -m "feat(perf): scale + haptic feedback on cards"
```

---

## Task 3: BouncingScrollPhysics + RepaintBoundary

**Files:**
- Modify: `lib/screens/home_screen.dart`

- [ ] **Step 1:** Ana `SingleChildScrollView` physics'ini değiştir

```dart
// Eski:
physics: const AlwaysScrollableScrollPhysics(),
// Yeni:
physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
```

- [ ] **Step 2:** Subject Carousel `ListView.builder` physics'ini değiştir

`_buildSubjectCarousel` içindeki `ListView.builder`'da:
```dart
// Eski: padding: const EdgeInsets.only(left: 20, right: 8),
// Ekle:
physics: const BouncingScrollPhysics(),
```

- [ ] **Step 3:** Ağır widget'ları `RepaintBoundary` ile sar

`_buildHeroCard(isDark)`, `_buildSubjectCarousel(isDark)`, `_buildDailyGoal(isDark)` çağrılarını Column içinde RepaintBoundary ile sar:

```dart
// Eski:
_buildStreakBanner(isDark),
_buildHeroCard(isDark),
const SizedBox(height: 20),
_buildQuickActions(isDark),
const SizedBox(height: 26),
_buildSubjectCarousel(isDark),
const SizedBox(height: 26),
_buildDailyGoal(isDark),

// Yeni:
_buildStreakBanner(isDark),
RepaintBoundary(child: _buildHeroCard(isDark)),
const SizedBox(height: 20),
_buildQuickActions(isDark),
const SizedBox(height: 26),
RepaintBoundary(child: _buildSubjectCarousel(isDark)),
const SizedBox(height: 26),
RepaintBoundary(child: _buildDailyGoal(isDark)),
```

- [ ] **Step 4:** `flutter analyze` → error yok → commit

```bash
git commit -m "feat(perf): bouncing scroll physics + repaint boundaries"
```

---

## Task 4: MaterialPageRoute → AppRoute

**Files:**
- Modify: `lib/screens/home_screen.dart`

- [ ] **Step 1:** Dosyada `MaterialPageRoute` geçen yerleri bul

`_buildHeroCard` içindeki AnkiCounter'larda:
```dart
// Eski (3 adet, newOnly / learnedOnly / pocketOnly için):
Navigator.push(context, MaterialPageRoute(
    builder: (_) => const FlashcardScreen(initialMode: FlashcardMode.newOnly)))

// Yeni:
Navigator.push(context, AppRoute.slideUp(
    const FlashcardScreen(initialMode: FlashcardMode.newOnly)))
```
Aynısını `learnedOnly` ve `pocketOnly` için de uygula.

- [ ] **Step 2:** `_buildDailyGoal` içindeki GoalSettingsScreen için:

```dart
// Eski:
MaterialPageRoute(builder: (_) => const GoalSettingsScreen())
// Yeni:
AppRoute.slideUp(const GoalSettingsScreen())
```

- [ ] **Step 3:** `flutter analyze` → error yok → commit

```bash
git commit -m "feat(perf): replace MaterialPageRoute with AppRoute.slideUp"
```
