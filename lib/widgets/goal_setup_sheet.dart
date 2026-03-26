import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/progress_model.dart';
import '../services/progress_service.dart';
import '../services/user_service.dart';
import '../services/premium_service.dart';
import '../widgets/paywall_widget.dart';

// ── Public entry point ────────────────────────────────────────────────────────

/// Opens the Akıllı Hedef Belirleme bottom sheet.
/// [onSaved] is called after the goal is successfully saved.
void showGoalSetupSheet(
  BuildContext context,
  bool isDark, {
  VoidCallback? onSaved,
}) {
  final progressService = ProgressService();
  final userService = UserService();
  final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

  bool sheetLoading = true;
  bool loadStarted = false;
  StudyProgress progress = StudyProgress();
  bool isPremium = false;
  double tempBase = 0;
  double tempTarget = 0;
  DateTime tempTargetDate = DateTime.now();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        if (!loadStarted) {
          loadStarted = true;
          Future.wait([
            progressService.loadProgressCached(),
            PremiumService().isPremium(),
          ]).then((results) {
            if (ctx.mounted) {
              setModalState(() {
                progress = results[0] as StudyProgress;
                isPremium = results[1] as bool;
                tempBase = progress.baseScore;
                tempTarget = progress.targetScore;
                tempTargetDate = DateTime.parse(progress.targetTusDate);
                sheetLoading = false;
              });
            }
          });
        }

        if (sheetLoading) {
          return Container(
            height: 220,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.background : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppTheme.neonGold.withValues(alpha: 0.15), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                CircularProgressIndicator(color: AppTheme.neonGold, strokeWidth: 2),
                const SizedBox(height: 16),
                Text('Veriler yükleniyor...', style: GoogleFonts.inter(color: subColor, fontSize: 13)),
              ],
            ),
          );
        }

        final targetStr = tempTargetDate.toIso8601String().split('T')[0];
        final recommendation = progress.copyWith(
          baseScore: tempBase,
          targetScore: tempTarget,
          targetTusDate: targetStr,
        ).recommendedDailyGoal;
        final days = progress.copyWith(targetTusDate: targetStr).daysToExam;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.background : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AppTheme.neonGold.withValues(alpha: 0.15), width: 1.5),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 32 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Akıllı Hedef Belirleme',
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Sınav başarınızı garantilemek için verilerinizi girin.',
                  style: GoogleFonts.inter(color: subColor, fontSize: 14)),
                const SizedBox(height: 32),
                GoalScoreInput(
                  label: 'Mevcut TUS Puanın',
                  value: tempBase,
                  color: AppTheme.cyan,
                  isDark: isDark,
                  onChanged: (val) => setModalState(() => tempBase = val),
                ),
                const SizedBox(height: 24),
                GoalScoreInput(
                  label: 'Hedeflediğin Puan',
                  value: tempTarget,
                  color: AppTheme.neonGold,
                  isDark: isDark,
                  onChanged: (val) => setModalState(() => tempTarget = val),
                ),
                const SizedBox(height: 24),
                GoalDateInput(
                  label: 'Hedef TUS Tarihi',
                  value: tempTargetDate,
                  color: AppTheme.neonPink,
                  isDark: isDark,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempTargetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 1000)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
                            primary: AppTheme.neonPink,
                            onPrimary: Colors.white,
                            surface: isDark ? AppTheme.surface : AppTheme.lightSurface,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setModalState(() => tempTargetDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: (!isPremium && recommendation >= PremiumService.dailyFreeFlashcardLimit)
                      ? () {
                          Navigator.of(ctx).pop();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const PaywallWidget(type: 'flashcard', dailyLimit: PremiumService.dailyFreeFlashcardLimit),
                          );
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: (!isPremium && recommendation > PremiumService.dailyFreeFlashcardLimit)
                          ? AppTheme.neonGold.withValues(alpha: 0.1)
                          : AppTheme.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: (!isPremium && recommendation > PremiumService.dailyFreeFlashcardLimit)
                            ? AppTheme.neonGold.withValues(alpha: 0.3)
                            : AppTheme.cyan.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPremium ? 'Önerilen Günlük Soru/Kart' : 'Günlük Limit (Ücretsiz)',
                                style: GoogleFonts.inter(color: subColor, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${isPremium ? recommendation : recommendation.clamp(0, PremiumService.dailyFreeFlashcardLimit)} Adet',
                                    style: GoogleFonts.inter(
                                      color: (!isPremium && recommendation > PremiumService.dailyFreeFlashcardLimit)
                                          ? AppTheme.neonGold
                                          : AppTheme.cyan,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (!isPremium && recommendation > PremiumService.dailyFreeFlashcardLimit) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.lock_rounded, size: 18, color: AppTheme.neonGold),
                                  ],
                                ],
                              ),
                              if (!isPremium && recommendation > PremiumService.dailyFreeFlashcardLimit)
                                Text(
                                  'Premium\'a geç: $recommendation kart/gün',
                                  style: GoogleFonts.inter(color: AppTheme.neonGold, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$days Gün Kaldı',
                              style: GoogleFonts.inter(color: subColor, fontSize: 12)),
                            Text('${tempTargetDate.day} ${_monthName(tempTargetDate.month)}',
                              style: GoogleFonts.inter(color: textColor, fontSize: 18, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final messenger = ScaffoldMessenger.of(context);
                      await progressService.saveScoreGoal(base: tempBase, target: tempTarget);
                      await progressService.saveGoalSettings(
                        weekdayGoalHours: progress.weekdayGoalHours,
                        weekendGoalHours: progress.weekendGoalHours,
                        targetTusDate: targetStr,
                      );
                      // Update user target date
                      try {
                        final user = await userService.loadUser();
                        await userService.saveUser(user.copyWith(targetDate: tempTargetDate));
                      } catch (_) {}
                      final effectiveGoal = isPremium
                          ? recommendation
                          : recommendation.clamp(0, PremiumService.dailyFreeFlashcardLimit);
                      await progressService.setDailyGoal(effectiveGoal);
                      if (Navigator.of(ctx).canPop()) {
                        Navigator.of(ctx).pop();
                      }
                      onSaved?.call();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Günlük hedefin ($effectiveGoal soru) güncellendi! 🚀'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cyan,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                    child: const Text('HEDEFİ ONAYLA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

String _monthName(int month) {
  const names = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  return names[month];
}

// ── GoalScoreInput ────────────────────────────────────────────────────────────

class GoalScoreInput extends StatefulWidget {
  final String label;
  final double value;
  final Color color;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const GoalScoreInput({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<GoalScoreInput> createState() => _GoalScoreInputState();
}

class _GoalScoreInputState extends State<GoalScoreInput> {
  late double _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  @override
  void didUpdateWidget(GoalScoreInput old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _localValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label,
                style: GoogleFonts.inter(color: textColor, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(_localValue.toStringAsFixed(1),
                style: GoogleFonts.inter(color: widget.color, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.color,
            thumbColor: widget.color,
            overlayColor: widget.color.withValues(alpha: 0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: _localValue,
            min: 40.0,
            max: 85.0,
            onChanged: (val) => setState(() => _localValue = val),
            onChangeEnd: widget.onChanged,
          ),
        ),
      ],
    );
  }
}

// ── GoalDateInput ─────────────────────────────────────────────────────────────

class GoalDateInput extends StatelessWidget {
  final String label;
  final DateTime value;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const GoalDateInput({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(color: textColor, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: isDark ? 0.25 : 0.15), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: color, size: 20),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sınav Günü', style: GoogleFonts.inter(color: subColor, fontSize: 11)),
                    Text('${value.day} ${_monthName(value.month)} ${value.year}',
                        style: GoogleFonts.inter(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.edit_calendar_rounded, color: color.withValues(alpha: 0.5), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
