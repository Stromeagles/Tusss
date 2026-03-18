import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../theme/app_theme.dart';
import '../models/topic_model.dart';
import '../services/data_service.dart';
import '../services/spaced_repetition_service.dart';
import '../widgets/difficulty_badge_widget.dart';
import '../models/subject_registry.dart';

enum FlashcardMode { all, dueOnly, pocketOnly }

class FlashcardScreen extends StatefulWidget {
  final Topic? topicFilter;
  final String? subjectId;
  final FlashcardMode initialMode;

  const FlashcardScreen({
    super.key,
    this.topicFilter,
    this.subjectId,
    this.initialMode = FlashcardMode.dueOnly,
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
    } else {
      cards = await _dataService.loadFlashcards(subjectId: widget.subjectId);
    }
    _allCards = cards;
    await _applyMode(cards);
  }

  void _showPocketToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('📦', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Text(
              'Cepte! 10 gün sonra tekrar sorulacak',
              style: TextStyle(
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
    List<Flashcard> result;
    if (_mode == FlashcardMode.dueOnly) {
      final dueIds =
          await _srService.filterDueCards(source.map((c) => c.id).toList());
      result = source.where((c) => dueIds.contains(c.id)).toList();
      if (result.isEmpty) result = source;
    } else if (_mode == FlashcardMode.pocketOnly) {
      final allData = await Future.wait(
          source.map((c) => _srService.getCardData(c.id)));
      result = <Flashcard>[];
      for (var i = 0; i < source.length; i++) {
        if (allData[i].isInPocket) result.add(source[i]);
      }
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

  String get _title {
    if (_mode == FlashcardMode.pocketOnly) return '📦 Cep Kartları';
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
          final quality = effectiveDir == CardSwiperDirection.top ? 4 : 1;
          final updated = await _srService.recordAnswer(card.id, quality);

          if (mounted) {
            setState(() {
              _swipeHistory.add(effectiveDir);
              if (effectiveDir == CardSwiperDirection.top) {
                _knownCount++;
                // Cepte! toast — 1+ tekrar sonrası bilindi
                if (updated.isInPocket) {
                  _showPocketToast();
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
              label: 'Bilmedim',
              color: AppTheme.error.withValues(alpha: 0.30)),
          _HintChip(
              icon: Icons.arrow_upward_rounded,
              label: 'Bildim',
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

  const _FlashCard({super.key, required this.card, required this.srService});

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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.success.withValues(alpha: 0.40)),
            ),
            child: const Text('CEVAP',
                style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 20),
          Text(widget.card.answer,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.5)),
          const Spacer(),
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
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: color,
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
      FlashcardMode.dueOnly   => ('Bugün',  Icons.filter_alt_rounded,    AppTheme.cyan),
      FlashcardMode.pocketOnly => ('Cep',    Icons.inventory_2_rounded,   AppTheme.success),
      FlashcardMode.all       => ('Tümü',   Icons.all_inclusive_rounded,  AppTheme.textMuted),
    };
    return GestureDetector(
      onTap: () {
        final next = switch (mode) {
          FlashcardMode.dueOnly    => FlashcardMode.all,
          FlashcardMode.all        => FlashcardMode.pocketOnly,
          FlashcardMode.pocketOnly => FlashcardMode.dueOnly,
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
