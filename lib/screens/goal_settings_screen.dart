import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/progress_service.dart';

class GoalSettingsScreen extends StatefulWidget {
  const GoalSettingsScreen({super.key});

  @override
  State<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends State<GoalSettingsScreen> {
  final _progressService = ProgressService();
  bool _loading = true;
  
  late double _weekdayHours;
  late double _weekendHours;
  late DateTime _targetDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final progress = await _progressService.loadProgress();
    setState(() {
      _weekdayHours = progress.weekdayGoalHours;
      _weekendHours = progress.weekendGoalHours;
      _targetDate = DateTime.parse(progress.targetTusDate);
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _progressService.saveGoalSettings(
      weekdayGoalHours: _weekdayHours,
      weekendGoalHours: _weekendHours,
      targetTusDate: _targetDate.toIso8601String().split('T')[0],
    );
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hedefler güncellendi! 🚀')),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1000)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.cyan,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Hedeflerini Belirle'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Sınav Tarihi'),
            const SizedBox(height: 12),
            _buildDateSelector(),
            const SizedBox(height: 32),
            _buildSectionTitle('Günlük Saat Hedefleri'),
            const SizedBox(height: 8),
            Text('Hafta içi ve hafta sonu için farklı hedefler belirleyebilirsin.', 
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            _buildHourSlider('Hafta İçi', _weekdayHours, (v) => setState(() => _weekdayHours = v)),
            const SizedBox(height: 32),
            _buildHourSlider('Hafta Sonu', _weekendHours, (v) => setState(() => _weekendHours = v)),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.cyan.withValues(alpha: 0.4),
                ),
                child: const Text('KAYDET VE BAŞLA', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, 
      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary));
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: AppTheme.cyan),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hedef TUS Tarihi', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${_targetDate.day} ${_getMonthName(_targetDate.month)} ${_targetDate.year}', 
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_rounded, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildHourSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${value.toInt()} Saat', style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 16,
          divisions: 15,
          activeColor: AppTheme.cyan,
          inactiveColor: AppTheme.divider,
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const names = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return names[month];
  }
}
