import 'package:flutter/material.dart';
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

enum FlashcardMode { all, dueOnly, pocketOnly, newOnly, learnedOnly, failedOnly }

class FlashcardScreen extends StatefulWidget {
  final Topic? topicFilter;
  final String? subjectId;
  final List<String>? subjectIds; // Çoklu branş filtresi (Günlük Hedef için)
  final FlashcardMode initialMode;
  final int? dailyGoal;

  const FlashcardScreen({
    super.key,
    this.topicFilter,
    this.subjectId,
    this.subjectIds,
    this.initialMode = FlashcardMode.dueOnly,
    this.dailyGoal,
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
  int _currentIndex = 0;
  int _knownCount = 0;
  int _unknownCount = 0;
  late FlashcardMode _mode;

  // Swipe geçmişi — Geri Al için
  final List<CardSwiperDirection> _swipeHistory = [];

  // Drag sırasında anlık % değerleri — dikey yön önceliği için
  int _dragPctY = 0;
  int? _pendingQuality;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _loadCards();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() => _loading = true);
    List<Flashcard> cards;
    if (widget.topicFilter != null) {
      cards = widget.topicFilter!.flashcards;
    } else if (widget.subjectIds != null && widget.subjectIds!.isNotEmpty) {
      // Çoklu branş: her branşın kartlarını birleştir
      final futures = widget.subjectIds!
          .map((id) => _dataService.loadFlashcards(subjectId: id));
      final results = await Future.wait(futures);
      cards = results.expand((c) => c).toList();
    } else {
      cards = await _dataService.loadFlashcards(subjectId: widget.subjectId);
    }
    _allCards = cards;
    await _applyMode(cards);
  }

  void _showAnswerToast(SM2CardData updated) {
    final isNowPocket = updated.isInPocket;
    final emoji = isNowPocket ? '🧠' : '📚';
    final message = isNowPocket
        ? 'Hafıza! 3 gün sonra tekrar sorulacak'
        : 'Bildiklerime alındı! Tekrar edilirse hafızaya geçecek';

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
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _applyMode(List<Flashcard> source) async {
    List<Flashcard> result = [];
    final allData = await Future.wait(
        source.map((c) => _srService.getCardData(c.id)));

    final allMap = await _srService.getAllData();

    if (_mode == FlashcardMode.learnedOnly) {
      // Bildiklerim: En az 1 kez çalışılmış (veya tekrar öğreniliyor), cepte değil
      for (var i = 0; i < source.length; i++) {
        if (allMap.containsKey(source[i].id) && allData[i].repetitions <= 1) {
          result.add(source[i]);
        }
      }
    } else if (_mode == FlashcardMode.dueOnly) {
      // Eski 'Tekrar' mantığı
      for (var i = 0; i < source.length; i++) {
        if (allData[i].isDue && !allData[i].isInPocket) result.add(source[i]);
      }
      if (result.isEmpty) result = source;
    } else if (_mode == FlashcardMode.newOnly) {
      // Yeni: Hiç görülmemiş kartlar
      for (var i = 0; i < source.length; i++) {
        if (!allMap.containsKey(source[i].id)) result.add(source[i]);
      }
      result.shuffle(); // Her seans farklı sıra
      if (widget.dailyGoal != null && widget.dailyGoal! > 0 && result.length > widget.dailyGoal!) {
        result = result.take(widget.dailyGoal!).toList();
      }
    } else if (_mode == FlashcardMode.pocketOnly) {
      for (var i = 0; i < source.length; i++) {
        if (allData[i].isInPocket) result.add(source[i]);
      }
    } else if (_mode == FlashcardMode.failedOnly) {
      final all = await _srService.getAllData();
      _cards = _allCards.where((fc) {
        final data = all[fc.id];
        return data != null && !data.isInPocket && data.repetitions == 0;
      }).toList();
      if (mounted) {
        setState(() {
          _currentIndex = 0;
          _knownCount = 0;
          _unknownCount = 0;
          _swipeHistory.clear();
          _loading = false;
        });
      }
      return;
    } else {
      result = source;
    }
    if (mounted) {
      setState(() {
        _cards = result;
        _currentIndex = 0;
        _knownCount = 0;
        _unknownCount = 0;
        _swipeHistory.clear();
        _loading = false;
      });
    }
  }

  Future<void> _rateAndSwipe(int quality) async {
    _pendingQuality = quality;
    _swiperController.swipe(
      quality >= 3 ? CardSwiperDirection.top : CardSwiperDirection.bottom,
    );
  }

  String get _title {
    if (_mode == FlashcardMode.pocketOnly) return '📦 Cep Kartları';
    if (_mode == FlashcardMode.newOnly) return '🆕 Yeni Kartlar';
    if (_mode == FlashcardMode.learnedOnly) return '🧠 Bildiklerim';
    if (widget.topicFilter != null) return widget.topicFilter!.subTopic;
    if (widget.subjectId != null) {
      final mod = SubjectRegistry.findById(widget.subjectId!);
      return mod != null ? '${mod.name} Kartları' : 'Flash Kartlar';
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.cyan))
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
              count: _knownCount, label: 'Bildim', color: AppTheme.success),
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
              label: 'Bilmedim',
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

          // ← SOL: Geri Al — kartı geri çek, önceki cevabı sil
          if (effectiveDir == CardSwiperDirection.left) {
            _pendingQuality = null;
            if (_swipeHistory.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _swiperController.undo();
                setState(() {
                  final lastDir = _swipeHistory.removeLast();
                  if (lastDir == CardSwiperDirection.top) {
                    _knownCount = (_knownCount - 1).clamp(0, 9999);
                  } else if (lastDir == CardSwiperDirection.bottom) {
                    _unknownCount = (_unknownCount - 1).clamp(0, 9999);
                  }
                  if (_currentIndex > 0) _currentIndex--;
                });
              });
            }
            return false; // Sola swipe iptal → kart geri döner
          }

          // → SAĞ: Ana Menü
          if (effectiveDir == CardSwiperDirection.right) {
            if (mounted) Navigator.of(context).pop();
            return true;
          }

          // ↑ YUKARI: Bildim (quality 4) | ↓ AŞAĞI: Bilmedim (quality 1)
          final card = _cards[prev];
          final quality = _pendingQuality ?? (effectiveDir == CardSwiperDirection.top ? 3 : 1);
          _pendingQuality = null;
          final SM2CardData updated;
          try {
            updated = await _srService.recordAnswer(card.id, quality);
          } catch (_) {
            return true;
          }

          if (mounted) {
            setState(() {
              _swipeHistory.add(effectiveDir);
              if (effectiveDir == CardSwiperDirection.top) {
                _knownCount++;
                // Toast: bildiklerime alındı veya cepte geçti
                if (updated.repetitions == 1 || updated.isInPocket) {
                  _showAnswerToast(updated);
                }
              } else {
                _unknownCount++;
              }
              _currentIndex = curr ?? _currentIndex;
            });
          }
          return true;
        },
        onEnd: () => setState(() {}),
        numberOfCardsDisplayed: _cards.length >= 3 ? 3 : _cards.length,
        backCardOffset: const Offset(0, 22),
        padding: const EdgeInsets.symmetric(vertical: 12),
        cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
          // Aktif kartın sürükleme yönünü takip et (onSwipe'da kullanılır)
          if (index == _currentIndex) {
            _dragPctY = percentThresholdY;
          }

          // Feedback glow: yukarı → yeşil, aşağı → kırmızı
          Color? glowColor;
          double intensity = 0.0;

          if (percentThresholdY < 0) {
            glowColor = AppTheme.success;
            intensity = (-percentThresholdY / 100.0).clamp(0.0, 1.0);
          } else if (percentThresholdY > 0) {
            glowColor = AppTheme.error;
            intensity = (percentThresholdY / 100.0).clamp(0.0, 1.0);
          }

          return Stack(
            children: [
              _FlashCard(
                key: ValueKey(_cards[index].id),
                card: _cards[index],
                srService: _srService,
                onRate: index == _currentIndex ? _rateAndSwipe : null,
              ),
              // Glow overlay
              if (glowColor != null && intensity > 0.04)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: glowColor.withValues(
                              alpha: (intensity * 0.9).clamp(0.0, 1.0)),
                          width: 2.5,
                        ),
                        color: glowColor.withValues(
                            alpha: (intensity * 0.13).clamp(0.0, 1.0)),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(
                                alpha: (intensity * 0.40).clamp(0.0, 1.0)),
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
                        color: glowColor.withValues(
                            alpha: (intensity * 0.92).clamp(0.0, 1.0)),
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
                        percentThresholdY < 0 ? '✓  Bildim' : '✗  Bilmedim',
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

  /// Buton yok — sadece silik jest ipuçları
  Widget _buildGestureHints() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HintChip(
              icon: Icons.arrow_back_rounded,
              label: 'Geri Al',
              color: AppTheme.textMuted.withValues(alpha: 0.40)),
          _HintChip(
              icon: Icons.arrow_downward_rounded,
              label: 'Tekrar',
              color: AppTheme.error.withValues(alpha: 0.30)),
          _HintChip(
              icon: Icons.arrow_upward_rounded,
              label: 'İyi',
              color: AppTheme.success.withValues(alpha: 0.30)),
          _HintChip(
              icon: Icons.arrow_forward_rounded,
              label: 'Menü',
              color: AppTheme.textMuted.withValues(alpha: 0.40)),
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

  const _FlashCard({super.key, required this.card, required this.srService, this.onRate});

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

  final _aiService = AIService();
  String? _mnemonic;
  bool _mnemonicLoading = false;

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
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _enterCtrl.dispose();
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
          // Zorluk + SR etiketi
          Row(
            children: [
              DifficultyBadge(difficulty: widget.card.difficulty),
              const Spacer(),
              if (_nextReviewLabel.isNotEmpty)
                _SRLabel(label: _nextReviewLabel),
            ],
          ),
          const Spacer(),
          const Text('SORU',
              style: TextStyle(
                  color: AppTheme.cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
          const SizedBox(height: 10),
          Text(widget.card.question,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.55)),
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
          // Üst etiket — soru yüzüyle aynı yükseklikte
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
          Text(widget.card.answer,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.55)),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RatingButton(label: '❌ Tekrar', color: const Color(0xFFFF453A), onTap: () => widget.onRate!(1)),
                _RatingButton(label: '😓 Zor',    color: const Color(0xFFFF9F0A), onTap: () => widget.onRate!(2)),
                _RatingButton(label: '✓ İyi',    color: const Color(0xFF30D158), onTap: () => widget.onRate!(3)),
                _RatingButton(label: '⭐ Kolay',  color: const Color(0xFF0A84FF), onTap: () => widget.onRate!(4)),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const Center(
            child: Text('↑ İyi  ·  ↓ Tekrar  ·  ← Geri Al',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ),
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
      FlashcardMode.dueOnly     => ('Bugün',    Icons.filter_alt_rounded,    AppTheme.cyan),
      FlashcardMode.pocketOnly  => ('Cep',      Icons.inventory_2_rounded,   AppTheme.success),
      FlashcardMode.all         => ('Tümü',     Icons.all_inclusive_rounded,  AppTheme.textMuted),
      FlashcardMode.newOnly     => ('Yeni',     Icons.auto_awesome_rounded,  AppTheme.neonPurple),
      FlashcardMode.learnedOnly => ('Öğrenilen', Icons.school_rounded,       AppTheme.neonGold),
      FlashcardMode.failedOnly  => ('Başarısız', Icons.replay_rounded,       AppTheme.error),
    };
    return GestureDetector(
      onTap: () {
        final next = switch (mode) {
          FlashcardMode.dueOnly     => FlashcardMode.all,
          FlashcardMode.all         => FlashcardMode.pocketOnly,
          FlashcardMode.pocketOnly  => FlashcardMode.newOnly,
          FlashcardMode.newOnly     => FlashcardMode.learnedOnly,
          FlashcardMode.learnedOnly => FlashcardMode.failedOnly,
          FlashcardMode.failedOnly  => FlashcardMode.dueOnly,
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
