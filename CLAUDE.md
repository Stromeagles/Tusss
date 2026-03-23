# CLAUDE.md — TUS Asistanı (AsisTus) Proje Kuralları

## Rol
Senior Flutter Developer & UI/UX Expert. Bu projede baş geliştirici olarak görev yapılır.

## Kod Standartları
- Kodlar her zaman modüler, Clean Architecture prensiplerine uygun, okunabilir ve performanslı olmalı
- Singleton pattern servisler için, Provider/ChangeNotifier state management için kullanılır
- `kIsWeb` ve `Platform` kontrolleri ile platform-aware kod yazılır
- Dart naming conventions: camelCase değişkenler, PascalCase sınıflar, snake_case dosyalar

## Tasarım Prensipleri
- UI her zaman premium hissettirmeli
- Koyu tema: `#0F172A` (background), `#161B22` (surface), `#F78166` (coral accent), `#A371F7` (violet)
- Cyan accent: `#00D4FF` (web ve logo)
- Glassmorphism: yarı-şeffaf kartlar, yumuşak gölgeler
- Font: Inter (Google Fonts)
- Pürüzsüz animasyonlar: flutter_animate kullanılır

## İş Akışı
- Büyük özellik eklemeden önce: "Önce Planla, Sonra Kodla"
- Değiştirilecek dosyalar ve adımlar sıralanır
- Mevcut mimari korunur, gereksiz karmaşıklıktan kaçınılır

## Hata Çözümü
- Geçici çözümler (patch) yerine kök neden analizi yapılır
- Kalıcı mimari çözümler üretilir
- Debug sırasında mevcut testler ve yapı bozulmaz

## Proje Yapısı
- `lib/services/` — Singleton servisler (AI, Auth, SM-2, Progress, Focus, vb.)
- `lib/screens/` — Ekranlar (home, flashcard, case_study, profile, vb.)
- `lib/models/` — Veri modelleri (Topic, SM2Card, UserProfile, Progress)
- `lib/widgets/` — Yeniden kullanılabilir widget'lar
- `lib/theme/` — Tema tanımları (app_theme.dart)
- `assets/data/` — 68 JSON tıbbi içerik dosyası

## Build & Run
```bash
flutter run -d chrome --dart-define=ANTHROPIC_API_KEY=sk-ant-...
flutter build web --release --base-href='/app/'
flutter build apk --release
```

## Önemli Notlar
- Firebase projesi: tusai-2fb30
- AI: Claude Haiku 4.5 (claude-haiku-4-5-20251001) — dual-layer cache
- SM-2 spaced repetition: 3-tier mastery (1=failed, 2=passed, 3+=mastered)
- Freemium: günlük 50 kart limiti (free), premium sınırsız
- Hedef kullanıcı: TUS'a hazırlanan Türk doktorlar
