import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/topic_model.dart';
import '../services/data_service.dart';
import '../services/progress_service.dart';
import '../services/ai_service.dart';
import '../models/subject_registry.dart';

class CaseStudyScreen extends StatefulWidget {
  /// Topic düzeyinde filtre.
  final Topic? topicFilter;

  /// Branş düzeyinde filtre.
  final String? subjectId;

  const CaseStudyScreen({super.key, this.topicFilter, this.subjectId});

  @override
  State<CaseStudyScreen> createState() => _CaseStudyScreenState();
}

class _CaseStudyScreenState extends State<CaseStudyScreen> {
  final _dataService = DataService();
  final _progressService = ProgressService();
  final _aiService = AIService();

  List<ClinicalCase> _cases = [];
  bool _loading = true;
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _correctCount = 0;

  // AI durumu
  bool _aiLoading = false;
  String? _aiExplanation;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  String _subjectName(String id) =>
      SubjectRegistry.findById(id)?.name ?? id;

  Future<void> _loadCases() async {
    List<ClinicalCase> cases;
    if (widget.topicFilter != null) {
      cases = widget.topicFilter!.clinicalCases;
    } else {
      cases = await _dataService.loadCases(
          subjectId: widget.subjectId);
    }
    if (mounted) {
      setState(() {
        _cases = cases;
        _loading = false;
      });
    }
  }

  ClinicalCase get _currentCase => _cases[_currentIndex];
  bool get _isCorrect => _selectedAnswer == _currentCase.correctAnswer;
  bool get _isLast => _currentIndex == _cases.length - 1;

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _aiExplanation = null;
      if (answer == _currentCase.correctAnswer) _correctCount++;
    });
    _progressService.recordCaseAnswer(
        correct: answer == _currentCase.correctAnswer);
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

  void _nextCase() {
    if (_isLast) {
      _showCompletionDialog();
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedAnswer = null;
      _answered = false;
      _aiExplanation = null;
      _aiLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.topicFilter != null
              ? widget.topicFilter!.subTopic
              : widget.subjectId != null
                  ? '${_subjectName(widget.subjectId!)} Vakaları'
                  : 'Klinik Vakalar',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (!_loading && _cases.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentIndex + 1}/${_cases.length}',
                  style: const TextStyle(
                      color: AppTheme.cyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.cyan))
          : _cases.isEmpty
              ? _buildEmptyState()
              : _buildCaseContent(),
    );
  }

  Widget _buildCaseContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            const SizedBox(height: 20),
            _buildNextButton(),
          ],
          const SizedBox(height: 32),
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_rounded,
                    color: AppTheme.cyan, size: 13),
                SizedBox(width: 6),
                Text('HASTA VAKASI',
                    style: TextStyle(
                        color: AppTheme.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentCase.caseText,
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
    return ElevatedButton.icon(
      onPressed: _nextCase,
      icon: Icon(_isLast
          ? Icons.done_all_rounded
          : Icons.arrow_forward_rounded),
      label:
          Text(_isLast ? 'Oturumu Tamamla' : 'Sonraki Vaka'),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_outlined,
              color: AppTheme.textMuted, size: 64),
          const SizedBox(height: 16),
          Text('Henüz vaka bulunmuyor',
              style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

// ── AI Açıklama bileşenleri ───────────────────────────────────────────────────

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
