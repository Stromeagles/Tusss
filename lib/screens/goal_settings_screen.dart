import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/progress_model.dart';
import '../services/progress_service.dart';

class GoalSettingsScreen extends StatefulWidget {
  final StudyProgress progress;

  const GoalSettingsScreen({super.key, required this.progress});

  @override
  State<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends State<GoalSettingsScreen> {
  final _service = ProgressService();

  late double _weekdayHours;
  late double _weekendHours;
  late DateTime _targetDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _weekdayHours = widget.progress.weekdayGoalHours;
    _weekendHours = widget.progress.weekendGoalHours;
    try {
      _targetDate = DateTime.parse(widget.progress.targetTusDate);
    } catch (_) {
      _targetDate = DateTime(2026, 6, 28);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.cyan,
            onPrimary: Colors.black,
            surface: Color(0xFF1C2128),
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _service.saveGoalSettings(
      weekdayGoalHours: _weekdayHours,
      weekendGoalHours: _weekendHours,
      targetTusDate:
          '${_targetDate.year}-${_targetDate.month.toString().padLeft(2, '0')}-${_targetDate.day.toString().padLeft(2, '0')}',
    );
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true); // true = kaydedildi sinyali
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardBg = AppTheme.glassBg(isDark, darkAlpha: 0.08, lightAlpha: 0.82);
    final cardBorder = AppTheme.glassBorder(isDark);

    final daysLeft = _targetDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFEDF3FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Hedef Ayarları',
            style: GoogleFonts.inter(
                color: textColor, fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── TUS Tarihi ────────────────────────────────────────────────
          _SectionCard(
            isDark: isDark, cardBg: cardBg, cardBorder: cardBorder,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TUS Sınav Tarihi',
                  style: GoogleFonts.inter(
                      color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Geri sayım bu tarihe göre hesaplanır.',
                  style: GoogleFonts.inter(color: subColor, fontSize: 12)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cyan.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: AppTheme.cyan, size: 20),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          '${_targetDate.day} ${_monthName(_targetDate.month)} ${_targetDate.year}',
                          style: GoogleFonts.inter(
                              color: AppTheme.cyan,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                        ),
                        Text('$daysLeft gün kaldı',
                            style: GoogleFonts.inter(
                                color: subColor, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                      const Spacer(),
                      Icon(Icons.edit_rounded, color: subColor, size: 16),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Hafta İçi Hedef ──────────────────────────────────────────
          _SectionCard(
            isDark: isDark, cardBg: cardBg, cardBorder: cardBorder,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.work_rounded, color: AppTheme.neonPink, size: 18),
                const SizedBox(width: 8),
                Text('Hafta İçi Günlük Hedef',
                    style: GoogleFonts.inter(
                        color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${_weekdayHours.toStringAsFixed(1)} saat',
                    style: GoogleFonts.inter(
                        color: AppTheme.neonPink, fontSize: 15, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 4),
              Text('Pazartesi – Cuma',
                  style: GoogleFonts.inter(color: subColor, fontSize: 12)),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.neonPink,
                  inactiveTrackColor: AppTheme.neonPink.withValues(alpha: 0.20),
                  thumbColor: AppTheme.neonPink,
                  overlayColor: AppTheme.neonPink.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: _weekdayHours,
                  min: 0.5, max: 12.0, divisions: 23,
                  onChanged: (v) => setState(() => _weekdayHours = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0.5 saat', style: GoogleFonts.inter(color: subColor, fontSize: 10)),
                  Text('12 saat', style: GoogleFonts.inter(color: subColor, fontSize: 10)),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Hafta Sonu Hedef ─────────────────────────────────────────
          _SectionCard(
            isDark: isDark, cardBg: cardBg, cardBorder: cardBorder,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.weekend_rounded, color: AppTheme.cyan, size: 18),
                const SizedBox(width: 8),
                Text('Hafta Sonu Günlük Hedef',
                    style: GoogleFonts.inter(
                        color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${_weekendHours.toStringAsFixed(1)} saat',
                    style: GoogleFonts.inter(
                        color: AppTheme.cyan, fontSize: 15, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 4),
              Text('Cumartesi – Pazar',
                  style: GoogleFonts.inter(color: subColor, fontSize: 12)),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.cyan,
                  inactiveTrackColor: AppTheme.cyan.withValues(alpha: 0.20),
                  thumbColor: AppTheme.cyan,
                  overlayColor: AppTheme.cyan.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: _weekendHours,
                  min: 0.5, max: 16.0, divisions: 31,
                  onChanged: (v) => setState(() => _weekendHours = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0.5 saat', style: GoogleFonts.inter(color: subColor, fontSize: 10)),
                  Text('16 saat', style: GoogleFonts.inter(color: subColor, fontSize: 10)),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 32),

          // ── Kaydet Butonu ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : Text('Kaydet',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return names[month];
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder, width: 1.0),
          ),
          child: child,
        ),
      ),
    );
  }
}
