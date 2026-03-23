import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mock_exam_model.dart';
import '../services/mock_exam_service.dart';
import '../theme/app_theme.dart';
import 'mock_exam_result_screen.dart';
import '../services/premium_service.dart';
import '../widgets/paywall_widget.dart';

class MockExamScreen extends StatefulWidget {
  final MockExamConfig config;

  const MockExamScreen({super.key, required this.config});

  @override
  State<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends State<MockExamScreen> {
  final _examService = MockExamService();
  bool _loading = true;
  bool _failed = false;
  
  // Premium / Limit
  final _premiumService = PremiumService();
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _examService.addListener(_rebuild);
    _setup();
  }

  @override
  void dispose() {
    _examService.removeListener(_rebuild);
    _examService.pauseTimer();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _setup() async {
    setState(() => _loading = true);
    final ok = await _examService.generateExam(widget.config);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    setState(() => _loading = false);
    _examService.startTimer(onTimeUp: _onTimeUp);
  }

  void _onTimeUp() {
    if (mounted) _finishExam();
  }

  Future<void> _finishExam() async {
    final result = await _examService.finishExam();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MockExamResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) return _buildLoading(isDark);
    if (_failed) return _buildFailed(isDark);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) _promptExit();
      },
      child: _limitReached
          ? const PaywallWidget(type: 'soru', dailyLimit: PremiumService.dailyFreeCaseLimit)
          : Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0F172A), Color(0xFF0A1628), Color(0xFF0F172A)]
                  : const [Color(0xFFEDF3FF), Color(0xFFE8F0FF), Color(0xFFF0F5FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(isDark),
                _buildTimerBar(isDark),
                Expanded(child: _buildQuestionArea(isDark)),
                _buildNavBar(isDark),
                _buildBottomActions(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final total = _examService.questions.length;
    final current = _examService.currentIndex + 1;
    final answered = _examService.answeredCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _promptExit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.close_rounded, color: textColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Soru $current / $total',
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text('$answered cevaplandı',
                    style: GoogleFonts.inter(
                        color: subColor, fontSize: 11)),
              ],
            ),
          ),
          // Zamanlayıcı
          _buildTimerChip(isDark),
        ],
      ),
    );
  }

  Widget _buildTimerChip(bool isDark) {
    final isWarning = _examService.isTimeWarning;
    final color = isWarning ? AppTheme.error : AppTheme.cyan;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: isWarning
            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            _examService.formattedRemaining,
            style: GoogleFonts.inter(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    ).animate(target: isWarning ? 1.0 : 0.0).shake(
        duration: 600.ms,
        hz: 3,
        offset: const Offset(1.5, 0));
  }

  Widget _buildTimerBar(bool isDark) {
    final progress = _examService.timeProgress;
    final isWarning = _examService.isTimeWarning;
    final barColor = isWarning ? AppTheme.error : AppTheme.cyan;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: 1 - progress,
          backgroundColor:
              isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          valueColor: AlwaysStoppedAnimation(barColor),
          minHeight: 3,
        ),
      ),
    );
  }

  Widget _buildQuestionArea(bool isDark) {
    final q = _examService.currentQuestion;
    if (q == null) return const SizedBox();

    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Konu etiketi
          if (q.subject.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neonPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(q.subject,
                  style: GoogleFonts.inter(
                      color: AppTheme.neonPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),

          // Soru metni
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Text(
              q.clinicalCase.cleanText,
              style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 14.5,
                  height: 1.7,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),

          // Şıklar
          ...q.clinicalCase.options.asMap().entries.map(
            (entry) => _buildOption(
                entry.key, entry.value, q, isDark, textColor, subColor),
          ),

          // Anlık geri bildirim açıklaması
          if (widget.config.showInstantFeedback &&
              q.isAnswered &&
              q.clinicalCase.explanation.isNotEmpty)
            _buildExplanation(q, isDark, textColor),
        ],
      ),
    ).animate(key: ValueKey(_examService.currentIndex)).fadeIn(duration: 200.ms);
  }

  Widget _buildOption(int idx, String option, ExamQuestion q, bool isDark,
      Color textColor, Color subColor) {
    final letter = String.fromCharCode(65 + idx); // A, B, C...
    final isSelected = q.selectedAnswer == option;
    final showFeedback = widget.config.showInstantFeedback && q.isAnswered;
    final isCorrect = option == q.clinicalCase.correctAnswer;

    Color borderColor;
    Color bgColor;

    if (showFeedback) {
      if (isCorrect) {
        borderColor = AppTheme.success.withValues(alpha: 0.5);
        bgColor = AppTheme.success.withValues(alpha: isDark ? 0.12 : 0.08);
      } else if (isSelected && !isCorrect) {
        borderColor = AppTheme.error.withValues(alpha: 0.5);
        bgColor = AppTheme.error.withValues(alpha: isDark ? 0.12 : 0.08);
      } else {
        borderColor = isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.06);
        bgColor = isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.white.withValues(alpha: 0.5);
      }
    } else {
      borderColor = isSelected
          ? AppTheme.cyan.withValues(alpha: 0.5)
          : (isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06));
      bgColor = isSelected
          ? AppTheme.cyan.withValues(alpha: isDark ? 0.12 : 0.08)
          : (isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.7));
    }

    return GestureDetector(
      onTap: () {
        if (showFeedback) return; // Instant feedback aktifse cevap değiştirilemez
        _examService.answerQuestion(_examService.currentIndex, option);
        
        // Günlük sayacı artır
        _premiumService.incrementCase();
        
        // Auto-advance in instant feedback mode
        if (widget.config.showInstantFeedback) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted &&
                _examService.currentIndex <
                    _examService.questions.length - 1) {
              _examService.nextQuestion();
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1),
          boxShadow: isSelected && !showFeedback
              ? [
                  BoxShadow(
                      color: AppTheme.cyan.withValues(alpha: 0.15),
                      blurRadius: 10)
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? (showFeedback
                        ? (isCorrect
                            ? AppTheme.success.withValues(alpha: 0.2)
                            : AppTheme.error.withValues(alpha: 0.2))
                        : AppTheme.cyan.withValues(alpha: 0.2))
                    : (showFeedback && isCorrect
                        ? AppTheme.success.withValues(alpha: 0.15)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? (showFeedback
                          ? (isCorrect ? AppTheme.success : AppTheme.error)
                          : AppTheme.cyan)
                      : (showFeedback && isCorrect
                          ? AppTheme.success
                          : subColor.withValues(alpha: 0.3)),
                ),
              ),
              child: Center(
                child: Text(letter,
                    style: GoogleFonts.inter(
                        color: isSelected
                            ? (showFeedback
                                ? (isCorrect ? AppTheme.success : AppTheme.error)
                                : AppTheme.cyan)
                            : (showFeedback && isCorrect
                                ? AppTheme.success
                                : subColor),
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(option,
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400)),
            ),
            if (showFeedback && isCorrect)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 18),
            if (showFeedback && isSelected && !isCorrect)
              const Icon(Icons.cancel_rounded,
                  color: AppTheme.error, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation(ExamQuestion q, bool isDark, Color textColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  color: AppTheme.success, size: 15),
              const SizedBox(width: 6),
              Text('Açıklama',
                  style: GoogleFonts.inter(
                      color: AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Text(q.clinicalCase.explanation,
              style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 12.5,
                  height: 1.55)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildNavBar(bool isDark) {
    final questions = _examService.questions;
    final current = _examService.currentIndex;

    return Container(
      height: 52,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        itemBuilder: (_, i) {
          final q = questions[i];
          final isCurrent = i == current;
          final isAnswered = q.isAnswered;
          final isFlagged = q.isFlagged;

          Color bgColor;
          Color borderColor;

          if (isCurrent) {
            bgColor = AppTheme.cyan.withValues(alpha: 0.25);
            borderColor = AppTheme.cyan;
          } else if (isAnswered) {
            bgColor = AppTheme.success.withValues(alpha: 0.15);
            borderColor = AppTheme.success.withValues(alpha: 0.4);
          } else if (isFlagged) {
            bgColor = AppTheme.warning.withValues(alpha: 0.15);
            borderColor = AppTheme.warning.withValues(alpha: 0.4);
          } else {
            bgColor = isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04);
            borderColor = isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.08);
          }

          return GestureDetector(
            onTap: () => _examService.goToQuestion(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 7, top: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Center(
                child: Text('${i + 1}',
                    style: GoogleFonts.inter(
                        color: isCurrent
                            ? AppTheme.cyan
                            : (isAnswered
                                ? AppTheme.success
                                : (isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.lightTextSecondary)),
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.w900
                            : FontWeight.w600)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions(bool isDark) {
    final isFirst = _examService.currentIndex == 0;
    final isLast =
        _examService.currentIndex == _examService.questions.length - 1;
    final q = _examService.currentQuestion;
    final isFlagged = q?.isFlagged ?? false;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 4, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          // Geri
          GestureDetector(
            onTap: isFirst ? null : _examService.previousQuestion,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: isFirst
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.03))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Icon(Icons.chevron_left_rounded,
                  color: isFirst
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.2))
                      : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
                  size: 24),
            ),
          ),
          const SizedBox(width: 10),

          // İşaretle
          GestureDetector(
            onTap: () => _examService.toggleFlag(_examService.currentIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: isFlagged
                    ? AppTheme.warning.withValues(alpha: 0.12)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFlagged
                      ? AppTheme.warning.withValues(alpha: 0.4)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06)),
                ),
              ),
              child: Icon(
                isFlagged ? Icons.flag_rounded : Icons.flag_outlined,
                color: isFlagged
                    ? AppTheme.warning
                    : (isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // İleri / Bitir
          Expanded(
            child: GestureDetector(
              onTap: isLast ? _finishExam : _nextQuestion,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: isLast
                      ? const LinearGradient(
                          colors: [AppTheme.cyan, Color(0xFFFF6B8A)])
                      : LinearGradient(
                          colors: isDark
                              ? [
                                  AppTheme.cyan.withValues(alpha: 0.20),
                                  AppTheme.cyan.withValues(alpha: 0.12),
                                ]
                              : [
                                  AppTheme.cyan.withValues(alpha: 0.15),
                                  AppTheme.cyan.withValues(alpha: 0.08),
                                ]),
                  borderRadius: BorderRadius.circular(14),
                  border: isLast
                      ? null
                      : Border.all(
                          color: AppTheme.cyan.withValues(alpha: 0.3)),
                  boxShadow: isLast
                      ? [
                          BoxShadow(
                              color: AppTheme.cyan.withValues(alpha: 0.35),
                              blurRadius: 12)
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'Sınavı Bitir' : 'İleri',
                      style: GoogleFonts.inter(
                          color: isLast
                              ? Colors.white
                              : AppTheme.cyan,
                          fontSize: 14,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isLast
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      color: isLast ? Colors.white : AppTheme.cyan,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _nextQuestion() async {
    // Limit kontrolü
    final limitReached = await _premiumService.isCaseLimitReached();
    if (limitReached && mounted) {
      setState(() => _limitReached = true);
      return;
    }
    _examService.nextQuestion();
  }

  void _promptExit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.surface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Sınavdan Çık?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text(
          'Sınav ilerlemeniz kaydedilmeyecek. Çıkmak istediğinize emin misiniz?',
          style: GoogleFonts.inter(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              _examService.resetExam();
              Navigator.pop(context); // dialog
              Navigator.pop(context); // exam screen
            },
            child: Text('Çık',
                style: GoogleFonts.inter(
                    color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppTheme.background : const Color(0xFFEDF3FF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                color: AppTheme.cyan, strokeWidth: 2),
            const SizedBox(height: 16),
            Text('Sorular hazırlanıyor...',
                style: GoogleFonts.inter(
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildFailed(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppTheme.background : const Color(0xFFEDF3FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.error, size: 56),
              const SizedBox(height: 16),
              Text('Soru bulunamadı',
                  style: GoogleFonts.inter(
                      color: isDark
                          ? AppTheme.textPrimary
                          : AppTheme.lightTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Seçili branşlarda yeterli vaka sorusu yok. Farklı branş seçin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 13,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cyan,
                    foregroundColor: Colors.white),
                child: Text('Geri Dön',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
