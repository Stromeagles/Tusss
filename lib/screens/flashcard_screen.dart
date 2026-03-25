import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/topic_model.dart';
import '../services/data_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/ai_service.dart';
import '../models/sm2_model.dart';
import '../widgets/difficulty_badge_widget.dart';
import '../models/subject_registry.dart';
import '../widgets/study_focus_timer.dart';
import '../utils/error_handler.dart';
import '../services/premium_service.dart';
import '../widgets/paywall_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/ai_chat_sheet.dart';
import '../widgets/add_to_collection_sheet.dart';

enum FlashcardMode { all, dueOnly, pocketOnly, newOnly, learnedOnly, failedOnly, criticalOnly }

class FlashcardScreen extends StatefulWidget {
  final Topic? topicFilter;
  final String? subjectId;
  final List<String>? subjectIds; // Çoklu branş filtresi (Günlük Hedef için)
  final FlashcardMode initialMode;
  final int? dailyGoal;
  final bool isPreview;

  const FlashcardScreen({
    super.key,
    this.topicFilter,
    this.subjectId,
    this.subjectIds,
    this.initialMode = FlashcardMode.dueOnly,
    this.dailyGoal,
    this.isPreview = false,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final _dataService = DataService();
  final _srService = SpacedRepetitionService();
  final CardSwiperController _swiperController = CardSwiperController();

  List<Flashcard> _allCards = [];
  List<Flashcard> _cards = [];
  bool _loading = true;
  bool _loadError = false;
  bool _isFinished = false;
  int _currentIndex = 0;
  int _knownCount = 0;
  int _unknownCount = 0;
  late FlashcardMode _mode;


  // Drag sırasında anlık % değerleri — dikey yön önceliği için
  int _dragPctY = 0;
  int? _pendingQuality;

  // Premium / Limit
  final _premiumService = PremiumService();
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _checkLimitAndLoad();
  }

  Future<void> _checkLimitAndLoad() async {
    // Premium kontrolü ve veri yüklemeyi paralel başlat
    final limitReachedFuture = _premiumService.isFlashcardLimitReached();

    // Veriyi şimdiden arka planda yükle (cache varsa anında döner)
    List<Flashcard> preloadedCards = [];
    try {
      if (widget.topicFilter != null) {
        preloadedCards = widget.topicFilter!.flashcards;
      } else if (widget.subjectIds != null && widget.subjectIds!.isNotEmpty) {
        final futures = widget.subjectIds!
            .map((id) => _dataService.loadFlashcards(subjectId: id));
        final resultsList = await Future.wait(futures);
        preloadedCards = resultsList.expand((c) => c).toList();
      } else {
        preloadedCards = await _dataService.loadFlashcards(subjectId: widget.subjectId);
      }
    } catch (_) {}

    final limitReached = await limitReachedFuture;

    if (limitReached && mounted) {
      setState(() {
        _limitReached = true;
        _loading = false;
      });
      return;
    }

    // Veri zaten hazır, sadece mode uygula
    if (preloadedCards.isNotEmpty) {
      _allCards = preloadedCards;
      await _applyMode(preloadedCards);
      if (_dataService.lastError != null && mounted) {
        ErrorHandler.showSnackbar(
          context,
          message: 'Bazı kart dosyaları yüklenemedi. Mevcut kartlarla devam ediliyor.',
          isError: false,
        );
      }
    } else {
      await _loadCards();
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      List<Flashcard> cards;
      if (widget.topicFilter != null) {
        cards = widget.topicFilter!.flashcards;
      } else if (widget.subjectIds != null && widget.subjectIds!.isNotEmpty) {
        final futures = widget.subjectIds!
            .map((id) => _dataService.loadFlashcards(subjectId: id));
        final results = await Future.wait(futures);
        cards = results.expand((c) => c).toList();
      } else {
        cards = await _dataService.loadFlashcards(subjectId: widget.subjectId);
      }
      _allCards = cards;
      await _applyMode(cards);

      if (_dataService.lastError != null && mounted) {
        ErrorHandler.showSnackbar(
          context,
          message: 'Bazi kart dosyalari yuklenemedi. Mevcut kartlarla devam ediliyor.',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = true;
        });
      }
    }
  }

  void _showAnswerToast(SM2CardData updated) {
    final isBildim = updated.lastQuality == 2;
    final days = updated.interval;
    final emoji = isBildim ? '✅' : '❌';
    final dayLabel = days == 1 ? 'Yarın' : '$days gün sonra';
    final message = isBildim
        ? 'Doğru! $dayLabel tekrar sorulacak'
        : 'Yanlış! $dayLabel tekrar sorulacak';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: isBildim ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _applyMode(List<Flashcard> source) async {
    List<Flashcard> result = [];
    final allMap = await _srService.getAllData();

    if (_mode == FlashcardMode.learnedOnly) {
      // Bildiklerim: lastQuality == 2
      result = source.where((fc) {
        final data = allMap[fc.id];
        return data != null && data.lastQuality == 2;
      }).toList();
    } else if (_mode == FlashcardMode.dueOnly) {
      // Öncelikli kartlar: Bilemediklerim (due) → Yeni → Bildiklerim (due)
      final dueBilemediklerim = <Flashcard>[];
      final yeniKartlar       = <Flashcard>[];
      final dueBildiklerim    = <Flashcard>[];

      for (final fc in source) {
        final data = allMap[fc.id];
        if (data == null) {
          yeniKartlar.add(fc);
        } else if (data.lastQuality == 1 && data.isDue) {
          dueBilemediklerim.add(fc);
        } else if (data.lastQuality == 2 && data.isDue) {
          dueBildiklerim.add(fc);
        }
      }
      // Sıralı gösterim — shuffle yok (Freemium: ücretsiz kullanıcı tüm havuzu tarayamasın)
      if (widget.dailyGoal != null && widget.dailyGoal! > 0 && yeniKartlar.length > widget.dailyGoal!) {
        yeniKartlar.removeRange(widget.dailyGoal!, yeniKartlar.length);
      }
      result = [...dueBilemediklerim, ...yeniKartlar, ...dueBildiklerim];
      if (result.isEmpty) result = source;
    } else if (_mode == FlashcardMode.newOnly) {
      // Yeni: Hiç görülmemiş kartlar
      result = source.where((fc) => !allMap.containsKey(fc.id)).toList();
      // Sıralı gösterim — shuffle yok
      if (widget.dailyGoal != null && widget.dailyGoal! > 0 && result.length > widget.dailyGoal!) {
        result = result.take(widget.dailyGoal!).toList();
      }
    } else if (_mode == FlashcardMode.pocketOnly) {
      // Ezberim: isBookmarked == true
      result = source.where((fc) {
        final data = allMap[fc.id];
        return data != null && data.isBookmarked;
      }).toList();
    } else if (_mode == FlashcardMode.failedOnly) {
      // Bilemediklerim: lastQuality == 1
      result = source.where((fc) {
        final data = allMap[fc.id];
        return data != null && data.lastQuality == 1;
      }).toList();
    } else if (_mode == FlashcardMode.criticalOnly) {
      // Kritik: aynı zamanda Bilemediklerim ile aynı (geriye dönük uyumluluk)
      result = source.where((fc) {
        final data = allMap[fc.id];
        return data != null && data.lastQuality == 1;
      }).toList();
    } else {
      result = source;
    }
    if (mounted) {
      setState(() {
        _cards = result;
        _currentIndex = 0;
        _knownCount = 0;
        _unknownCount = 0;
        _isFinished = false;
        _loading = false;
      });
    }
  }

  Future<void> _rateAndSwipe(int quality) async {
    _pendingQuality = quality;
    _swiperController.swipe(
      quality == 2 ? CardSwiperDirection.top : CardSwiperDirection.bottom,
    );
  }

  String get _title {
    if (_mode == FlashcardMode.pocketOnly) return 'Favoriler';
    if (_mode == FlashcardMode.newOnly) return 'Yeni Kartlar';
    if (_mode == FlashcardMode.learnedOnly) return 'Doğrular';
    if (_mode == FlashcardMode.criticalOnly) return 'Yanlışlar';
    if (_mode == FlashcardMode.failedOnly) return 'Yanlışlar';
    if (widget.topicFilter != null) return widget.topicFilter!.subTopic;
    if (widget.subjectId != null) {
      final mod = SubjectRegistry.findById(widget.subjectId!);
      return mod != null ? mod.name : 'Flash Kartlar';
    }
    return 'Flash Kartlar';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontSize: 16)),
        actions: [
          const StudyFocusTimer(),
          if (widget.dailyGoal != null && widget.dailyGoal! > 0 && !_loading && _cards.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neonGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.neonGold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${_knownCount + _unknownCount}/${widget.dailyGoal} Hedef',
                  style: TextStyle(
                    color: AppTheme.neonGold.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          // Klasöre Ekle butonu
          if (!_loading && _cards.isNotEmpty && _currentIndex < _cards.length)
            IconButton(
              icon: const Icon(Icons.folder_outlined, color: AppTheme.neonPurple, size: 22),
              tooltip: 'Klasöre Ekle',
              onPressed: () {
                final card = _cards[_currentIndex];
                AddToCollectionSheet.show(
                  context,
                  cardId: card.id,
                  cardTitle: card.question.length > 50
                      ? '${card.question.substring(0, 50)}...'
                      : card.question,
                );
              },
            ),
          // AI'ya Sor butonu
          if (!_loading && _cards.isNotEmpty && _currentIndex < _cards.length)
            IconButton(
              icon: const Icon(Icons.psychology_rounded, color: AppTheme.cyan, size: 22),
              tooltip: "AI'ya Sor",
              onPressed: () {
                final card = _cards[_currentIndex];
                AiChatSheet.show(
                  context,
                  cardContext: 'Soru: ${card.question}\nCevap: ${card.answer}',
                  cardTitle: card.question.length > 50
                      ? '${card.question.substring(0, 50)}...'
                      : card.question,
                );
              },
            ),
          _ModeToggle(
            mode: _mode,
            onChanged: (m) async {
              setState(() => _mode = m);
              await _applyMode(_allCards);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _limitReached
          ? const PaywallWidget(type: 'flashcard', dailyLimit: PremiumService.dailyFreeFlashcardLimit)
          : _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.cyan))
          : _loadError
              ? ErrorHandler.buildFallbackScreen(
                  isDark: true,
                  title: 'Kartlar Yuklenemedi',
                  message: 'Flashcard verileri okunurken hata olustu.',
                  onRetry: _loadCards,
                )
              : _isFinished
                  ? _buildCompletionSummary()
                  : _cards.isEmpty
                      ? _buildEmptyState()
                      : Column(
                      children: [
                        _buildScoreboard(),
                        _buildProgressBar(),
                        Expanded(child: _buildSwiper()),
                        _buildGestureHints(),
                        const SizedBox(height: 24),
                      ],
                    ),
    );
  }

  Widget _buildScoreboard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          _ScoreChip(
              count: _knownCount, label: 'Doğru', color: AppTheme.success),
          const Spacer(),
          Text(
            '${_currentIndex < _cards.length ? _currentIndex + 1 : _cards.length}/${_cards.length}',
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          _ScoreChip(
              count: _unknownCount,
              label: 'Yanlış',
              color: AppTheme.error),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final done = _knownCount + _unknownCount;
    final progress = _cards.isEmpty ? 0.0 : done / _cards.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: AppTheme.surfaceVariant,
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyan),
        borderRadius: BorderRadius.circular(4),
        minHeight: 4,
      ),
    );
  }

  Widget _buildSwiper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CardSwiper(
        controller: _swiperController,
        cardsCount: _cards.length,
        isLoop: false,
        onSwipe: (prev, curr, dir) async {
          // Dikey yön önceliği: sürükleme sırasında Y bileşeni anlamlıysa
          // kütüphanenin "sağ/sol" tespitini yukarı/aşağı olarak düzelt.
          // Böylece yukarı-sağ çapraz swipe "Bildim" olarak tanınır.
          CardSwiperDirection effectiveDir = dir;
          if ((dir == CardSwiperDirection.right ||
                  dir == CardSwiperDirection.left) &&
              _dragPctY.abs() > 40) {
            effectiveDir = _dragPctY < 0
                ? CardSwiperDirection.top
                : CardSwiperDirection.bottom;
          }

          // ← SOL: yoksay — sola swipe etkisizleştirildi
          if (effectiveDir == CardSwiperDirection.left) {
            return false;
          }

          // → SAĞ veya ↑ YUKARI: Bildim — her ikisi de aynı aksiyonu tetikler
          if (effectiveDir == CardSwiperDirection.right) {
            effectiveDir = CardSwiperDirection.top; // Sağ = Bildim
          }

          // ↑ YUKARI: Bildim (quality 2) | ↓ AŞAĞI: Bilemedim (quality 1)
          final card = _cards[prev];
          final quality = _pendingQuality ?? (effectiveDir == CardSwiperDirection.top ? 2 : 1);
          _pendingQuality = null;
          SM2CardData? updated;
          if (!widget.isPreview) {
            try {
              updated = await _srService.recordAnswer(card.id, quality);
            } catch (_) {
              return true;
            }
          }

          // Günlük sayacı artır
          _premiumService.incrementFlashcard();

          if (mounted) {
            // Limit kontrolü
            final limitReached = await _premiumService.isFlashcardLimitReached();

            setState(() {
              if (effectiveDir == CardSwiperDirection.top) {
                _knownCount++;
                if (updated != null) _showAnswerToast(updated);
              } else {
                _unknownCount++;
                // Bilemedim: Kartı sona ekle
                if (quality == 1) {
                  _cards.add(card);
                }
              }
              _currentIndex = curr ?? _currentIndex;
              if (limitReached) _limitReached = true;
            });

            if (limitReached) return false;
          }
          return true;
        },
        onEnd: () {
          if (mounted) setState(() => _isFinished = true);
        },
        numberOfCardsDisplayed: _cards.length >= 3 ? 3 : _cards.length,
        backCardOffset: const Offset(0, 22),
        padding: const EdgeInsets.symmetric(vertical: 12),
        cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
          // Aktif kartın sürükleme yönünü takip et (onSwipe'da kullanılır)
          if (index == _currentIndex) {
            _dragPctY = percentThresholdY;
          }

          // Feedback glow: yukarı/sağ → yeşil (Doğru), aşağı → kırmızı (Yanlış)
          Color? glowColor;
          double intensity = 0.0;

          if (percentThresholdY < 0) {
            glowColor = AppTheme.success;
            intensity = (-percentThresholdY / 100.0).clamp(0.0, 1.0);
          } else if (percentThresholdY > 0) {
            glowColor = AppTheme.error;
            intensity = (percentThresholdY / 100.0).clamp(0.0, 1.0);
          } else if (percentThresholdX > 0) {
            // Sağa kaydırma da "Bildim" — yeşil glow
            glowColor = AppTheme.success;
            intensity = (percentThresholdX / 100.0).clamp(0.0, 1.0);
          }

          return Stack(
            children: [
              _FlashCard(
                key: ValueKey(_cards[index].id),
                card: _cards[index],
                srService: _srService,
                onRate: index == _currentIndex ? _rateAndSwipe : null,
                isPreview: widget.isPreview,
              ),
              // Glow overlay
              if (glowColor != null && intensity > 0.04)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: glowColor.withValues(alpha: (intensity * 0.9).clamp(0.0, 1.0)),
                          width: 2.5,
                        ),
                        color: glowColor.withValues(alpha: (intensity * 0.13).clamp(0.0, 1.0)),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: (intensity * 0.40).clamp(0.0, 1.0)),
                            blurRadius: 32,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Bildim / Bilmedim etiketi
              if (glowColor != null && intensity > 0.25)
                Positioned(
                  top: percentThresholdY < 0 ? null : 18,
                  bottom: percentThresholdY < 0 ? 18 : null,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 9),
                      decoration: BoxDecoration(
                        color: glowColor.withValues(alpha: (intensity * 0.92).clamp(0.0, 1.0)),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.35),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        percentThresholdY < 0 ? '✅  Doğru' : '❌  Yanlış',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompletionSummary() {
    final successRate = _cards.isEmpty ? 0 : (_knownCount / _cards.length * 100).toInt();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, color: AppTheme.neonGold, size: 80)
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'Oturum Tamamlandı!',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bugünlük bu kadar yeterli. Harika gidiyorsun!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem('Doğrular', _knownCount.toString(), AppTheme.success),
                const SizedBox(width: 40),
                _buildStatItem('Başarı', '%$successRate', AppTheme.cyan),
              ],
            ),
            
            const SizedBox(height: 60),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.cyan.withValues(alpha: 0.4),
                ),
                child: const Text('ANA SAYFAYA DÖN', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
            
            if (_unknownCount > 0) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _applyMode(_allCards),
                child: Text(
                  'Yanlışları Tekrarla ($_unknownCount)',
                  style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  /// Buton yok — sadece silik jest ipuçları
  Widget _buildGestureHints() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _HintChip(
              icon: Icons.arrow_downward_rounded,
              label: 'Yanlış',
              color: AppTheme.error.withValues(alpha: 0.30)),
          _HintChip(
              icon: Icons.arrow_upward_rounded,
              label: 'Doğru',
              color: AppTheme.success.withValues(alpha: 0.30)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDue = _mode == FlashcardMode.dueOnly;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppTheme.success, size: 72),
            const SizedBox(height: 20),
            Text(
              isDue ? 'Bugünlük hepsi tamam!' : 'Tüm kartları bitirdin!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isDue
                  ? 'Spaced repetition algoritması bir sonraki tekrar tarihini planladı.'
                  : 'Müthiş bir çalışma oturumu!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            if (isDue)
              OutlinedButton.icon(
                onPressed: () async {
                  setState(() => _mode = FlashcardMode.all);
                  await _applyMode(_allCards);
                },
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.cyan),
                label: const Text('Tüm kartları çalış',
                    style: TextStyle(color: AppTheme.cyan)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.cyan),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Flash Card (flip + entrance animasyonlu) ──────────────────────────────────

class _FlashCard extends StatefulWidget {
  final Flashcard card;
  final SpacedRepetitionService srService;
  final void Function(int quality)? onRate;
  final bool isPreview;

  const _FlashCard({super.key, required this.card, required this.srService, this.onRate, this.isPreview = false});

  @override
  State<_FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<_FlashCard> with TickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  late AnimationController _enterCtrl;
  late Animation<double> _enterFade;
  late Animation<double> _enterScale;

  bool _showAnswer = false;
  String _nextReviewLabel = '';
  bool _isBookmarked = false;
  int? _lastQuality; // 1 = Bilemedim, 2 = Bildim (öğrenildi)

  final _aiService = AIService();
  String? _mnemonic;
  bool _mnemonicLoading = false;

  // Hangi cloze (buzlu) alanların açıldığı — ValueNotifier ile tüm kart rebuild'i önlenir
  final ValueNotifier<Set<int>> _revealedClozes = ValueNotifier(<int>{});

  // Blur: sadece [[]] içeren VE daha önce "Bildim" işaretlenmiş kartlarda aktif
  bool get _shouldBlur =>
      _lastQuality == 2 &&
      (widget.card.question.contains('[[') || widget.card.answer.contains('[['));

  @override
  void initState() {
    super.initState();

    // Flip
    _flipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _flipAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 0.5)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 0.5, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
    ]).animate(_flipCtrl);

    // Giriş animasyonu
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
    _enterFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterScale = Tween<double>(begin: 0.94, end: 1.0).animate(
        CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _enterCtrl.forward();

    _loadNextReview();
    _loadBookmarkState();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _enterCtrl.dispose();
    _revealedClozes.dispose();
    super.dispose();
  }

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

  Future<void> _loadNextReview() async {
    final label = await widget.srService.getNextReviewLabel(widget.card.id);
    if (mounted) setState(() => _nextReviewLabel = label);
  }

  Future<void> _loadBookmarkState() async {
    final data = await widget.srService.getCardData(widget.card.id);
    if (mounted) {
      setState(() {
        _isBookmarked = data.isBookmarked;
        _lastQuality = data.lastQuality;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (widget.isPreview) return;
    final updated = await widget.srService.toggleBookmark(widget.card.id);
    if (mounted) setState(() => _isBookmarked = updated.isBookmarked);
  }

  void _flip() {
    _showAnswer ? _flipCtrl.reverse() : _flipCtrl.forward();
    setState(() => _showAnswer = !_showAnswer);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _enterFade,
      child: ScaleTransition(
        scale: _enterScale,
        child: GestureDetector(
          onTap: _flip,
          child: AnimatedBuilder(
            animation: _flipAnim,
            builder: (_, __) {
              final isFirst = _flipAnim.value < 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_flipAnim.value * 3.14159),
                child: isFirst
                    ? _buildFront()
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(3.14159),
                        child: _buildBack(),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.cyan.withValues(alpha: 0.30), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppTheme.cyan.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zorluk + Bookmark + SR etiketi
          Row(
            children: [
              DifficultyBadge(difficulty: widget.card.difficulty),
              const Spacer(),
              GestureDetector(
                onTap: _toggleBookmark,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                    key: ValueKey(_isBookmarked),
                    color: _isBookmarked ? AppTheme.neonGold : AppTheme.textMuted,
                    size: 22,
                  ),
                ),
              ),
              if (_nextReviewLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                _SRLabel(label: _nextReviewLabel),
              ],
            ],
          ),
          const Spacer(),
          Builder(builder: (_) {
            // Soru metninden konu parse et: "Soru:(Konu) ..."
            final topicMatch = RegExp(r'Soru:\(([^)]+)\)').firstMatch(widget.card.question);
            final topic = topicMatch?.group(1) ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cyanGlow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                topic.isNotEmpty
                    ? 'SORU : ( ${topic.toUpperCase()} )'
                    : 'SORU',
                style: const TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8),
              ),
            );
          }),
          const SizedBox(height: 10),
          _ClozeText(
            text: widget.card.question.replaceFirst(RegExp(r'Soru:\([^)]+\)\s*'), ''),
            shouldBlur: false, // Soruda genelde buzlama istemeyiz ama altyapı hazır
            revealedIndices: _revealedClozes,
            onReveal: (idx) {
              _revealedClozes.value = {..._revealedClozes.value, idx};
            },
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.55),
          ),
          const Spacer(),
          const Center(
            child: Text('Cevabı görmek için dokun',
                style:
                    TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.success.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppTheme.success.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: CEVAP etiketi + Bookmark
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.40)),
                ),
                child: const Text('CEVAP',
                    style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleBookmark,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isBookmarked ? Icons.star_rounded : Icons.star_border_rounded,
                    key: ValueKey(_isBookmarked),
                    color: _isBookmarked ? AppTheme.neonGold : AppTheme.textMuted,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _ClozeText(
            text: widget.card.answer,
            shouldBlur: _shouldBlur,
            revealedIndices: _revealedClozes,
            onReveal: (idx) {
              _revealedClozes.value = {..._revealedClozes.value, idx};
            },
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.55),
          ),
          const Spacer(),
          // Hikaye / Mnemonic bölümü
          if (widget.card.storyHint != null && widget.card.storyHint!.isNotEmpty)
            _MnemonicBox(text: widget.card.storyHint!, isPremium: true)
          else if (_mnemonicLoading)
            const _ThinkingIndicator()
          else if (_mnemonic != null)
            _MnemonicBox(text: _mnemonic!)
          else
            _MnemonicButton(onTap: _generateMnemonic),
          const SizedBox(height: 12),
          if (widget.onRate != null) ...[
            Row(
              children: [
                Expanded(child: _RatingButton(
                  label: '❌  Yanlış',
                  color: const Color(0xFFFF453A),
                  onTap: () {
                    setState(() => _lastQuality = 1);
                    widget.onRate!(1);
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _RatingButton(
                  label: '✅  Doğru',
                  color: const Color(0xFF30D158),
                  onTap: () {
                    setState(() => _lastQuality = 2);
                    widget.onRate!(2);
                  },
                )),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ── Yardımcı widget'lar ───────────────────────────────────────────────────────

class _SRLabel extends StatelessWidget {
  final String label;
  const _SRLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDue = label == 'Bugün' || label == 'Yeni kart';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDue
            ? AppTheme.cyan.withValues(alpha: 0.12)
            : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                isDue ? AppTheme.cyan.withValues(alpha: 0.4) : AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDue
                ? Icons.notifications_active_rounded
                : Icons.schedule_rounded,
            color: isDue ? AppTheme.cyan : AppTheme.textMuted,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: isDue ? AppTheme.cyan : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Silik jest yönlendirme çipi — hem kart içinde hem altta kullanılır
class _HintChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HintChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.45), size: 14), // Made more faint
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: color.withValues(alpha: 0.45), // Made more faint
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _ScoreChip(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$count',
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final FlashcardMode mode;
  final void Function(FlashcardMode) onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (mode) {
      FlashcardMode.learnedOnly  => ('Doğrular',  Icons.check_circle_rounded, AppTheme.success),
      FlashcardMode.failedOnly   => ('Yanlışlar', Icons.cancel_rounded,       AppTheme.error),
      FlashcardMode.pocketOnly   => ('Favoriler', Icons.bookmark_rounded,     AppTheme.neonGold),
      _                          => ('Doğrular',  Icons.check_circle_rounded, AppTheme.success),
    };
    return GestureDetector(
      onTap: () {
        final next = switch (mode) {
          FlashcardMode.learnedOnly => FlashcardMode.failedOnly,
          FlashcardMode.failedOnly  => FlashcardMode.pocketOnly,
          FlashcardMode.pocketOnly  => FlashcardMode.learnedOnly,
          _                         => FlashcardMode.learnedOnly,
        };
        onChanged(next);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

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
  final bool isPremium;
  const _MnemonicBox({required this.text, this.isPremium = false});

  @override
  Widget build(BuildContext context) {
    final color = isPremium ? AppTheme.neonGold : AppTheme.neonPurple;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(isPremium ? '🎨' : '🧠', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              isPremium ? 'ÖZEL HİKAYE' : 'AI İPUCU',
              style: TextStyle(
                color: color.withValues(alpha: 0.80),
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

// ── Cloze Text (Buzlanmış Metin) ──────────────────────────────────────────

class _ClozeText extends StatelessWidget {
  final String text;
  final bool shouldBlur;
  final ValueNotifier<Set<int>> revealedIndices;
  final Function(int) onReveal;
  final TextStyle style;

  const _ClozeText({
    required this.text,
    required this.shouldBlur,
    required this.revealedIndices,
    required this.onReveal,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (!text.contains('[[')) {
      return Text(text, style: style);
    }
    // ValueListenableBuilder: sadece bu widget yeniden çizilir, kart tree'si değil
    return ValueListenableBuilder<Set<int>>(
      valueListenable: revealedIndices,
      builder: (_, revealed, __) => _buildSpans(revealed),
    );
  }

  Widget _buildSpans(Set<int> revealedSet) {
    final List<InlineSpan> spans = [];
    final regExp = RegExp(r'\[\[(.*?)\]\]');
    int start = 0;
    int index = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final content = match.group(1) ?? '';
      final currentIdx = index;
      final isRevealed = revealedSet.contains(currentIdx);

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () {
            if (shouldBlur && !isRevealed) {
              onReveal(currentIdx);
              HapticFeedback.lightImpact();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: shouldBlur && !isRevealed
                  ? AppTheme.textMuted.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: shouldBlur && !isRevealed
                    ? AppTheme.textMuted.withValues(alpha: 0.30)
                    : Colors.transparent,
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                   Text(content, style: style),
                  if (shouldBlur && !isRevealed)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ));

      start = match.end;
      index++;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
    );
  }
}

