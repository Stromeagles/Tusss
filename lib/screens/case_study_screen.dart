import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/topic_model.dart';
import '../services/data_service.dart';
import '../services/progress_service.dart';
import '../services/ai_service.dart';
import '../services/spaced_repetition_service.dart';
import '../models/sm2_model.dart';
import '../models/subject_registry.dart';
import '../widgets/study_focus_timer.dart';
import '../utils/error_handler.dart';
import '../services/premium_service.dart';
import '../widgets/paywall_widget.dart';
import '../widgets/ai_chat_sheet.dart';

enum CaseStudyMode { all, dueOnly, pocketOnly, newOnly, learnedOnly, failedOnly }

class CaseStudyScreen extends StatefulWidget {
  /// Topic düzeyinde filtre.
  final Topic? topicFilter;

  /// Branş düzeyinde filtre.
  final String? subjectId;

  /// Çoklu branş filtresi (Günlük Hedef/Karma için)
  final List<String>? subjectIds;

  /// Başlangıç modu
  final CaseStudyMode initialMode;

  /// Günlük hedef (yeni sorular için sınır)
  final int? dailyGoal;

  /// Önizleme modu — true ise ilerleme ve SRS kaydedilmez.
  final bool isPreview;

  const CaseStudyScreen({
    super.key,
    this.topicFilter,
    this.subjectId,
    this.subjectIds,
    this.initialMode = CaseStudyMode.all,
    this.dailyGoal,
    this.isPreview = false,
  });

  @override
  State<CaseStudyScreen> createState() => _CaseStudyScreenState();
}

class _CaseStudyScreenState extends State<CaseStudyScreen> {
  final _dataService = DataService();
  final _progressService = ProgressService();
  final _aiService = AIService();
  final _srService = SpacedRepetitionService();

  List<ClinicalCase> _allCases = [];
  List<ClinicalCase> _cases = [];
  bool _loading = true;
  bool _loadError = false;
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _correctCount = 0;
  bool _isBookmarked = false;
  late CaseStudyMode _mode;

  // AI durumu
  bool _aiLoading = false;
  String? _aiExplanation;

  // Premium / Limit
  final _premiumService = PremiumService();
  bool _limitReached = false;
  bool _isPremium = false;
  int _remaining = PremiumService.dailyFreeCaseLimit;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final results = await Future.wait([
      _premiumService.isPremium(),
      _premiumService.remainingCases(),
      _premiumService.isCaseLimitReached(),
    ]);

    final premium      = results[0] as bool;
    final remaining    = results[1] as int;
    final limitReached = results[2] as bool;

    if (!mounted) return;
    setState(() {
      _isPremium = premium;
      _remaining = remaining;
    });

    if (limitReached) {
      setState(() {
        _limitReached = true;
        _loading = false;
      });
      return;
    }
    _loadCases();
  }

  String _subjectName(String id) =>
      SubjectRegistry.findById(id)?.name ?? id;

  Future<void> _loadCases() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      List<ClinicalCase> cases;
      if (widget.topicFilter != null) {
        cases = widget.topicFilter!.clinicalCases;
      } else if (widget.subjectIds != null && widget.subjectIds!.isNotEmpty) {
        final futures = widget.subjectIds!
            .map((id) => _dataService.loadCases(subjectId: id));
        final results = await Future.wait(futures);
        cases = results.expand((c) => c).toList();
      } else {
        cases = await _dataService.loadCases(subjectId: widget.subjectId);
      }
      _allCases = cases;
      await _applyMode(cases);

      // DataService'de hata varsa kullanıcıya bildir (kısmi yükleme)
      if (_dataService.lastError != null && mounted) {
        ErrorHandler.showSnackbar(
          context,
          message: 'Bazı veriler yüklenemedi. Mevcut verilerle devam ediliyor.',
          isError: false,
          onRetry: _loadCases,
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

  Future<void> _applyMode(List<ClinicalCase> source) async {
    List<ClinicalCase> result = [];
    final allMap = await _srService.getAllData();

    if (_mode == CaseStudyMode.learnedOnly) {
      result = source.where((cc) {
        final data = allMap[cc.id];
        return data != null && data.lastQuality == 2;
      }).toList();
    } else if (_mode == CaseStudyMode.failedOnly) {
      result = source.where((cc) {
        final data = allMap[cc.id];
        return data != null && data.lastQuality == 1;
      }).toList();
    } else if (_mode == CaseStudyMode.pocketOnly) {
      result = source.where((cc) {
        final data = allMap[cc.id];
        return data != null && data.isBookmarked;
      }).toList();
    } else if (_mode == CaseStudyMode.newOnly) {
      result = source.where((cc) => !allMap.containsKey(cc.id)).toList();
      // Sıralı gösterim — shuffle yok
      if (widget.dailyGoal != null && widget.dailyGoal! > 0 && result.length > widget.dailyGoal!) {
        result = result.take(widget.dailyGoal!).toList();
      }
    } else if (_mode == CaseStudyMode.dueOnly) {
      final dueFailed  = <ClinicalCase>[];
      final newCases   = <ClinicalCase>[];
      final dueLearned = <ClinicalCase>[];

      for (final cc in source) {
        final data = allMap[cc.id];
        if (data == null) {
          newCases.add(cc);
        } else if (data.lastQuality == 1 && data.isDue) {
          dueFailed.add(cc);
        } else if (data.lastQuality == 2 && data.isDue) {
          dueLearned.add(cc);
        }
      }
      // Sıralı gösterim — shuffle yok
      if (widget.dailyGoal != null && widget.dailyGoal! > 0 && newCases.length > widget.dailyGoal!) {
        newCases.removeRange(widget.dailyGoal!, newCases.length);
      }
      result = [...dueFailed, ...newCases, ...dueLearned];
      if (result.isEmpty) result = List.from(source);
    } else {
      result = List.from(source);
    }

    if (mounted) {
      setState(() {
        _cases = result;
        _currentIndex = 0;
        _loading = false;
      });
      _loadBookmarkState();
    }
  }

  Future<void> _loadBookmarkState() async {
    if (_cases.isEmpty) return;
    final data = await _srService.getCardData(_currentCase.id);
    if (mounted) setState(() => _isBookmarked = data.isBookmarked);
  }

  Future<void> _toggleBookmark() async {
    if (widget.isPreview) {
      // Preview modda sadece UI'da göster, veritabanına kaydetme
      setState(() => _isBookmarked = !_isBookmarked);
      return;
    }
    final updated = await _srService.toggleBookmark(_currentCase.id);
    if (mounted) setState(() => _isBookmarked = updated.isBookmarked);
  }

  ClinicalCase get _currentCase => _cases[_currentIndex];
  bool get _isCorrect => _selectedAnswer == _currentCase.correctAnswer;
  bool get _isLast => _currentIndex == _cases.length - 1;

  Future<void> _selectAnswer(String answer) async {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _aiExplanation = null;
      if (answer == _currentCase.correctAnswer) _correctCount++;
    });
    // Günlük sayacı artır
    await _premiumService.incrementCase();
    if (!widget.isPreview) {
      _progressService.recordCaseAnswer(
          caseId: _currentCase.id,
          correct: answer == _currentCase.correctAnswer);

      // SRS entegrasyonu: doğru → quality 2 (Bildim), yanlış → quality 1 (Bilemedim)
      final caseId = _currentCase.id;
      if (caseId.isNotEmpty) {
        final quality = answer == _currentCase.correctAnswer ? 2 : 1;
        final updated = await _srService.recordAnswer(caseId, quality);
        if (mounted) {
          _showReviewFeedback(updated);
        }
      }
    }
  }

  Future<void> _fetchAIExplanation() async {
    setState(() {
      _aiLoading = true;
      _aiExplanation = null;
    });
    final explanation =
        await _aiService.getExplanation(_currentCase);
    if (mounted) {
      setState(() {
        _aiLoading = false;
        _aiExplanation = explanation;
      });
    }
  }

  Future<void> _nextCase() async {
    if (_isLast) {
      _showCompletionDialog();
      return;
    }
    // Limit kontrolü
    final limitReached = await _premiumService.isCaseLimitReached();
    if (limitReached && mounted) {
      setState(() => _limitReached = true);
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedAnswer = null;
      _answered = false;
      _aiExplanation = null;
      _aiLoading = false;
    });
    _loadBookmarkState();
  }

  void _showReviewFeedback(SM2CardData updated) {
    final days = updated.interval;
    final label = days == 1 ? 'Yarın tekrar' : '$days gün sonra tekrar';
    final isCorrect = updated.lastQuality == 2;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.schedule_rounded : Icons.replay_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: isCorrect
            ? AppTheme.success.withValues(alpha: 0.85)
            : AppTheme.warning.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Oturum Tamamlandı!',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_correctCount/${_cases.length} doğru',
              style: const TextStyle(
                  color: AppTheme.cyan,
                  fontSize: 34,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Başarı: %${(_correctCount / _cases.length * 100).toInt()}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Ana Sayfa',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _selectedAnswer = null;
                _answered = false;
                _correctCount = 0;
                _aiExplanation = null;
              });
            },
            child: const Text('Tekrar Çöz'),
          ),
        ],
      ),
    );
  }

  String get _title {
    if (_mode == CaseStudyMode.pocketOnly) return 'Favoriler';
    if (_mode == CaseStudyMode.failedOnly) return 'Yanlışlar';
    if (_mode == CaseStudyMode.learnedOnly) return 'Doğrular';
    if (_mode == CaseStudyMode.newOnly) return 'Yeni Sorular';

    if (widget.topicFilter != null) return widget.topicFilter!.subTopic;
    if (widget.subjectId != null) return _subjectName(widget.subjectId!);
    if (_mode == CaseStudyMode.dueOnly) return 'Günün Tekrarları';
    return 'Klinik Vakalar';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontSize: 16)),
        actions: [
          const StudyFocusTimer(),
          if (!_loading && _cases.isNotEmpty) ...[
            // AI'ya Sor butonu
            if (_currentIndex < _cases.length)
              IconButton(
                icon: const Icon(Icons.psychology_rounded, color: AppTheme.cyan, size: 22),
                tooltip: "AI'ya Sor",
                onPressed: () {
                  final caseItem = _cases[_currentIndex];
                  AiChatSheet.show(
                    context,
                    cardContext: 'Soru: ${caseItem.caseText}\n'
                        'Seçenekler: ${caseItem.options.join(", ")}\n'
                        'Doğru Cevap: ${caseItem.correctAnswer}',
                    cardTitle: caseItem.caseText.length > 50
                        ? '${caseItem.caseText.substring(0, 50)}...'
                        : caseItem.caseText,
                  );
                },
              ),
            _CaseModeToggle(
              mode: _mode,
              onChanged: (m) async {
                setState(() => _mode = m);
                await _applyMode(_allCases);
              },
            ),
            IconButton(
              onPressed: _toggleBookmark,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  _isBookmarked ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                  key: ValueKey(_isBookmarked),
                  color: _isBookmarked ? AppTheme.cyan : AppTheme.textSecondary,
                ),
              ),
              tooltip: _isBookmarked ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_currentIndex + 1} / ${_cases.length}',
                      style: const TextStyle(
                          color: AppTheme.cyan,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                    if (widget.dailyGoal != null && widget.dailyGoal! > 0)
                      Text(
                        'Hedef: ${widget.dailyGoal}',
                        style: TextStyle(
                          color: AppTheme.neonGold.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      body: _limitReached
          ? const PaywallWidget(type: 'soru', dailyLimit: PremiumService.dailyFreeCaseLimit)
          : _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.cyan))
          : _loadError
              ? ErrorHandler.buildFallbackScreen(
                  isDark: true,
                  title: 'Sorular Yuklenemedi',
                  message: 'Veri dosyalari okunurken hata olustu. Lutfen uygulamayi yeniden baslatmayi deneyin.',
                  onRetry: _loadCases,
                )
              : _cases.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        Expanded(child: _buildCaseContent()),
                        if (_answered)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: _buildNextButton(),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildCaseContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isPremium) _buildTrialBanner(),
          _buildProgressIndicator(),
          const SizedBox(height: 20),
          _buildCaseCard(),
          const SizedBox(height: 20),
          _buildOptions(),
          if (_answered) ...[
            const SizedBox(height: 20),
            _buildResultBanner(),
            const SizedBox(height: 16),
            _buildExplanationCard(),
            const SizedBox(height: 16),
            _buildAISection(),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTrialBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonGold.withValues(alpha: 0.10),
            AppTheme.neonPurple.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.neonGold.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: AppTheme.neonGold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bugün $_remaining TUS sorusu hakkın kaldı',
              style: const TextStyle(
                color: AppTheme.neonGold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _limitReached = true),
            child: Text(
              'Premium Ol →',
              style: TextStyle(
                color: AppTheme.neonGold.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.neonGold.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return LinearProgressIndicator(
      value: (_currentIndex + 1) / _cases.length,
      backgroundColor: AppTheme.surfaceVariant,
      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyan),
      borderRadius: BorderRadius.circular(4),
      minHeight: 4,
    );
  }

  Widget _buildCaseCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.cyan.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.cyanGlow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_rounded,
                    color: AppTheme.cyan, size: 13),
                const SizedBox(width: 6),
                Text(
                  _currentCase.topic.isNotEmpty
                      ? 'SORU : ( ${_currentCase.topic.toUpperCase()} )'
                      : 'SORU',
                  style: const TextStyle(
                      color: AppTheme.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentCase.cleanText.isNotEmpty
                ? _currentCase.cleanText
                : _currentCase.caseText,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: _currentCase.options.map((option) {
        Color borderColor = AppTheme.divider;
        Color textColor = AppTheme.textPrimary;
        Color bgColor = AppTheme.surfaceVariant;
        IconData? trailingIcon;

        if (_answered) {
          if (option == _currentCase.correctAnswer) {
            borderColor = AppTheme.success;
            textColor = AppTheme.success;
            bgColor = AppTheme.success.withValues(alpha: 0.08);
            trailingIcon = Icons.check_circle_rounded;
          } else if (option == _selectedAnswer) {
            borderColor = AppTheme.error;
            textColor = AppTheme.error;
            bgColor = AppTheme.error.withValues(alpha: 0.08);
            trailingIcon = Icons.cancel_rounded;
          }
        } else if (option == _selectedAnswer) {
          borderColor = AppTheme.cyan;
          bgColor = AppTheme.cyanGlow;
        }

        return GestureDetector(
          onTap: () => _selectAnswer(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(option,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4)),
                ),
                if (trailingIcon != null)
                  Icon(trailingIcon, color: borderColor, size: 22),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isCorrect
            ? AppTheme.success.withValues(alpha: 0.12)
            : AppTheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isCorrect
              ? AppTheme.success.withValues(alpha: 0.4)
              : AppTheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.emoji_events_rounded : Icons.close_rounded,
            color: _isCorrect ? AppTheme.success : AppTheme.error,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            _isCorrect ? 'Doğru! Harika!' : 'Yanlış.',
            style: TextStyle(
              color: _isCorrect ? AppTheme.success : AppTheme.error,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (!_isCorrect) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Doğru: ${_currentCase.correctAnswer}',
                maxLines: 1,
                style: const TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: AppTheme.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _currentCase.explanation,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISection() {
    if (_aiExplanation != null) {
      return _AIExplanationCard(explanation: _aiExplanation!);
    }

    return _AIRequestButton(
      isLoading: _aiLoading,
      onTap: _fetchAIExplanation,
    );
  }

  Widget _buildNextButton() {
    final isLast = _isLast;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _nextCase,
        icon: Icon(
          isLast ? Icons.done_all_rounded : Icons.arrow_forward_rounded,
          size: 22,
        ),
        label: Text(
          isLast ? 'Sonuçları Göster' : 'Sonraki Soru',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isLast ? AppTheme.neonGold : AppTheme.cyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          shadowColor: (isLast ? AppTheme.neonGold : AppTheme.cyan).withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDue = _mode == CaseStudyMode.dueOnly;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppTheme.success, size: 64),
          const SizedBox(height: 16),
          Text(isDue ? 'Bugünlük hepsi tamam!' : 'Henüz vaka bulunmuyor',
              style: Theme.of(context).textTheme.titleLarge),
          if (isDue) ...[
            const SizedBox(height: 8),
            const Text('Tüm vakaları tekrar gözden geçirebilirsin.',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                setState(() => _mode = CaseStudyMode.all);
                _applyMode(_allCases);
              },
              child: const Text('Tümünü Göster'),
            ),
          ]
        ],
      ),
    );
  }
}

// ── CaseModeToggle ──────────────────────────────────────────────────────────

class _CaseModeToggle extends StatelessWidget {
  final CaseStudyMode mode;
  final ValueChanged<CaseStudyMode> onChanged;

  const _CaseModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CaseStudyMode>(
      initialValue: mode,
      icon: Icon(
        _getIcon(mode),
        color: _getColor(mode),
        size: 20,
      ),
      onSelected: onChanged,
      color: AppTheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        _buildItem(CaseStudyMode.learnedOnly, 'Doğrular', AppTheme.success),
        _buildItem(CaseStudyMode.failedOnly, 'Yanlışlar', AppTheme.error),
        _buildItem(CaseStudyMode.pocketOnly, 'Favoriler', AppTheme.neonGold),
      ],
    );
  }

  PopupMenuItem<CaseStudyMode> _buildItem(CaseStudyMode value, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(_getIcon(value), color: color, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  IconData _getIcon(CaseStudyMode m) {
    switch (m) {
      case CaseStudyMode.dueOnly: return Icons.replay_rounded;
      case CaseStudyMode.failedOnly: return Icons.cancel_rounded;
      case CaseStudyMode.learnedOnly: return Icons.check_circle_rounded;
      case CaseStudyMode.pocketOnly: return Icons.bookmark_rounded;
      case CaseStudyMode.all: return Icons.grid_view_rounded;
      case CaseStudyMode.newOnly: return Icons.new_releases_rounded;
    }
  }

  Color _getColor(CaseStudyMode m) {
    switch (m) {
      case CaseStudyMode.dueOnly: return AppTheme.cyan;
      case CaseStudyMode.failedOnly: return AppTheme.error;
      case CaseStudyMode.learnedOnly: return AppTheme.success;
      case CaseStudyMode.pocketOnly: return AppTheme.neonGold;
      default: return AppTheme.textSecondary;
    }
  }
}

class _AIRequestButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _AIRequestButton(
      {required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7928CA).withValues(alpha: 0.15),
              const Color(0xFF00D4FF).withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF7928CA).withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7928CA).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Color(0xFF7928CA),
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFF9F7AEA), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading
                        ? 'AI açıklama hazırlanıyor...'
                        : 'AI ile Detaylı Açıkla',
                    style: const TextStyle(
                        color: Color(0xFFB794F4),
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoading
                        ? 'Claude analiz ediyor...'
                        : 'Patofizyoloji · Ayırıcı tanı · TUS püf noktaları',
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!isLoading)
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF9F7AEA), size: 14),
          ],
        ),
      ),
    );
  }
}

class _AIExplanationCard extends StatelessWidget {
  final String explanation;
  const _AIExplanationCard({required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7928CA).withValues(alpha: 0.10),
            const Color(0xFF00D4FF).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF7928CA).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF9F7AEA), size: 16),
              const SizedBox(width: 8),
              const Text('AI Açıklama',
                  style: TextStyle(
                      color: Color(0xFFB794F4),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7928CA).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Claude',
                    style: TextStyle(
                        color: Color(0xFF9F7AEA),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MarkdownText(text: explanation),
        ],
      ),
    );
  }
}

/// Minimal markdown: **bold** ve madde işaretlerini destekler.
class _MarkdownText extends StatelessWidget {
  final String text;
  const _MarkdownText({required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) return const SizedBox(height: 6);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _parseLine(line),
        );
      }).toList(),
    );
  }

  Widget _parseLine(String line) {
    // Başlık satırı: **text**
    if (line.startsWith('**') && line.endsWith('**')) {
      return Text(
        line.replaceAll('**', ''),
        style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.5),
      );
    }

    // Bold inline: parçalara böl
    final spans = <TextSpan>[];
    final parts = line.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: i % 2 == 1 ? FontWeight.w700 : FontWeight.w400,
          height: 1.6,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
