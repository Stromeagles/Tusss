import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/theme_service.dart';
import '../services/progress_service.dart';
import '../models/progress_model.dart';
import '../services/spaced_repetition_service.dart';
import '../services/auth_service.dart';
import '../auth/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'auth/login_screen.dart';
import '../services/specialty_score_service.dart';
import 'specialty_detail_screen.dart';
import '../widgets/goal_setup_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  UserProfile _user = const UserProfile();
  bool _loading = true;

  // İstatistikler
  int _totalSolved = 0;
  int _correctCount = 0;
  int _srsCardCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _userService.loadUser(),
      ProgressService().loadProgressCached(),
      SpacedRepetitionService().getAllData(),
    ]);

    if (mounted) {
      final user     = results[0] as UserProfile;
      final progress = results[1] as StudyProgress;
      final srsData  = results[2] as Map<String, dynamic>;
      setState(() {
        _user = user;
        _totalSolved = progress.totalFlashcardsStudied + progress.totalCasesAttempted;
        _correctCount = progress.correctAnswers;
        _srsCardCount = srsData.length;
        _loading = false;
      });
    }
  }

  double get _accuracy =>
      _totalSolved > 0 ? (_correctCount / _totalSolved * 100) : 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.cyan, strokeWidth: 2.5))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Bar ─────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  expandedHeight: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color: textColor, size: 20),
                    onPressed: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: () => _showEditSheet(context, isDark),
                      icon: Icon(Icons.edit_rounded,
                          color: AppTheme.cyan, size: 16),
                      label: Text('Düzenle',
                          style: GoogleFonts.inter(
                              color: AppTheme.cyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // ── Avatar + İsim ───────────────────────────────
                        _buildAvatarSection(textColor, subColor, isDark),
                        const SizedBox(height: 28),

                        // ── İstatistik Kartları ─────────────────────────
                        _buildStatsRow(isDark),
                        const SizedBox(height: 16),

                        // ── Ayarlar ─────────────────────────────────────
                        _buildSettingsSection(isDark, textColor, subColor),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Avatar + İsim ──────────────────────────────────────────────────────────

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (picked == null) return;

    // Kalıcı dizine kopyala
    String savedPath;
    if (kIsWeb) {
      savedPath = picked.path;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final ext = picked.path.split('.').last;
      final dest = '${dir.path}/profile_photo.$ext';
      final bytes = await picked.readAsBytes();
      final file = File(dest);
      await file.writeAsBytes(bytes);
      savedPath = dest;
    }

    final updated = _user.copyWith(profileImagePath: savedPath);
    await _userService.saveUser(updated);
    if (mounted) setState(() => _user = updated);
  }

  Widget _buildAvatarSection(Color textColor, Color subColor, bool isDark) {
    final hasImage = _user.profileImagePath != null && _user.profileImagePath!.isNotEmpty;

    return Column(
      children: [
        // Gradient Avatar with photo overlay
        GestureDetector(
          onTap: _pickProfileImage,
          child: Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasImage ? null : const LinearGradient(
                    colors: [AppTheme.cyan, AppTheme.neonPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: hasImage && !kIsWeb
                      ? DecorationImage(
                          image: FileImage(File(_user.profileImagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.cyan.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2),
                  ],
                ),
                child: hasImage
                    ? null
                    : Center(
                        child: Text(
                          _user.profileEmoji,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
              ),
              // Kamera ikonu
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.cyan,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppTheme.background : AppTheme.lightBackground,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cyan.withValues(alpha: 0.40),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text(
          _user.name,
          style: GoogleFonts.inter(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.neonPurple.withValues(alpha: isDark ? 0.15 : 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    AppTheme.neonPurple.withValues(alpha: isDark ? 0.30 : 0.20),
                width: 1),
          ),
          child: Text(
            _user.targetBranch,
            style: GoogleFonts.inter(
                color: AppTheme.neonPurple,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }

  // ── İstatistik Kartları ────────────────────────────────────────────────────

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
            child: _StatMini(
                label: 'Çözülen',
                value: '$_totalSolved',
                icon: Icons.check_circle_outline_rounded,
                color: AppTheme.success,
                isDark: isDark)),
        const SizedBox(width: 10),
        Expanded(
            child: _StatMini(
                label: 'Doğruluk',
                value: '${_accuracy.toStringAsFixed(0)}%',
                icon: Icons.analytics_outlined,
                color: AppTheme.cyan,
                isDark: isDark)),
        const SizedBox(width: 10),
        Expanded(
            child: _StatMini(
                label: 'SRS Kart',
                value: '$_srsCardCount',
                icon: Icons.style_outlined,
                color: AppTheme.neonPurple,
                isDark: isDark)),
      ],
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  // ── Tema Chip ──────────────────────────────────────────────────────────────

  Widget _themeChip(IconData icon, String label, bool selected, AppThemeMode target, bool isDark) {
    return GestureDetector(
      onTap: () => ThemeService.setMode(target),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.cyan.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
              color: selected ? AppTheme.cyan : (isDark ? Colors.white54 : Colors.black38)),
            const SizedBox(width: 4),
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppTheme.cyan : (isDark ? Colors.white54 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ayarlar ────────────────────────────────────────────────────────────────

  Widget _buildSettingsSection(
      bool isDark, Color textColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ayarlar',
            style: GoogleFonts.inter(
                color: subColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),

        // Hedef Ayarla
        _SettingsTile(
          icon: Icons.track_changes_rounded,
          label: 'Akıllı Hedef Belirleme',
          isDark: isDark,
          color: AppTheme.neonGold,
          onTap: () => showGoalSetupSheet(context, isDark, onSaved: _load),
        ),

        // Tema — 3'lü Segmented Control
        _SettingsTile(
          icon: Icons.palette_rounded,
          label: 'Tema',
          isDark: isDark,
          trailing: ValueListenableBuilder<AppThemeMode>(
            valueListenable: ThemeService.mode,
            builder: (_, mode, __) => Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _themeChip(Icons.dark_mode_rounded, 'Koyu',
                      mode == AppThemeMode.dark, AppThemeMode.dark, isDark),
                  _themeChip(Icons.light_mode_rounded, 'Açık',
                      mode == AppThemeMode.light, AppThemeMode.light, isDark),
                  _themeChip(Icons.visibility_rounded, 'Soft',
                      mode == AppThemeMode.soft, AppThemeMode.soft, isDark),
                ],
              ),
            ),
          ),
        ),

        // Hatırlatıcı
        _SettingsTile(
          icon: Icons.notifications_active_outlined,
          label: 'Günlük Hatırlatıcı',
          isDark: isDark,
          trailing: Switch.adaptive(
            value: _user.reminderEnabled,
            onChanged: (val) async {
              final updated = _user.copyWith(reminderEnabled: val);
              await _userService.saveUser(updated);
              setState(() => _user = updated);
            },
            activeTrackColor: AppTheme.cyan,
          ),
        ),

        // Verileri Sıfırla
        _SettingsTile(
          icon: Icons.delete_outline_rounded,
          label: 'Çalışma Verilerini Sıfırla',
          isDark: isDark,
          color: AppTheme.error,
          onTap: () => _showResetDialog(isDark),
        ),

        // Hakkında
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          label: 'Hakkında & Destek',
          isDark: isDark,
          onTap: () => _showAboutSheet(context, isDark),
        ),

        // Oturumu Kapat
        _SettingsTile(
          icon: Icons.logout_rounded,
          label: 'Oturumu Kapat',
          isDark: isDark,
          color: AppTheme.error,
          onTap: () => _logout(isDark),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  // ── Düzenleme Bottom Sheet ─────────────────────────────────────────────────

  // ── Premium Input Decoration ──────────────────────────────────────────────
  InputDecoration _premiumInput({
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: isDark ? AppTheme.textMuted : AppTheme.lightTextSecondary.withValues(alpha: 0.5),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, size: 20,
        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.cyan, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }

  // ── Branş Seçim Bottom Sheet ────────────────────────────────────────────
  void _showBranchPicker(BuildContext ctx, bool isDark, String current, void Function(String) onSelect) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setBS) {
          final query = searchCtrl.text.toLowerCase();
          final filtered = UserProfile.branches
              .where((b) => b.toLowerCase().contains(query))
              .toList();

          return Container(
            height: MediaQuery.of(sheetCtx).size.height * 0.65,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Uzmanlık Dalı Seçin',
                          style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchCtrl,
                        style: GoogleFonts.inter(
                            color: textColor, fontSize: 14),
                        decoration: _premiumInput(
                            hint: 'Ara...',
                            icon: Icons.search_rounded,
                            isDark: isDark),
                        onChanged: (_) => setBS(() {}),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final branch = filtered[i];
                      final selected = branch == current;
                      final imgPath =
                          SpecialtyScoreService.getImagePath(branch);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        tileColor: selected
                            ? AppTheme.cyan.withValues(alpha: 0.1)
                            : null,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  imgPath,
                                  fit: BoxFit.cover,
                                  cacheWidth: 96,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black
                                            .withValues(alpha: 0.35),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        title: Text(
                          branch,
                          style: GoogleFonts.inter(
                            color: selected ? AppTheme.cyan : textColor,
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  sheetCtx,
                                  MaterialPageRoute<void>(
                                    builder: (_) => SpecialtyDetailScreen(
                                        branchName: branch),
                                  ),
                                );
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppTheme.cyan
                                      .withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppTheme.cyan,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: selected ? AppTheme.cyan : subColor,
                              size: 20,
                            ),
                          ],
                        ),
                        onTap: () {
                          onSelect(branch);
                          Navigator.pop(sheetCtx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Premium Profil Düzenleme Sheet ──────────────────────────────────────
  void _showEditSheet(BuildContext context, bool isDark) {
    final nameCtrl = TextEditingController(text: _user.name);
    var tempUser = _user;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final textColor =
              isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
          final subColor =
              isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 20, 24,
                        MediaQuery.of(ctx).viewInsets.bottom + 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: subColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Profili Düzenle',
                            style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text(
                            'Bilgilerini güncelleyerek TUS yolculuğunu kişiselleştir',
                            style: GoogleFonts.inter(
                                color: subColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w400)),
                        const SizedBox(height: 28),
                        // FOTOĞRAF bölümü — avatardan önce
                        Text('FOTOĞRAF',
                            style: GoogleFonts.inter(color: subColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.pop(ctx);
                              await _pickProfileImage();
                              if (mounted) _showEditSheet(context, isDark);
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: (_user.profileImagePath == null || _user.profileImagePath!.isEmpty)
                                        ? const LinearGradient(colors: [AppTheme.cyan, AppTheme.neonPink], begin: Alignment.topLeft, end: Alignment.bottomRight)
                                        : null,
                                    image: (_user.profileImagePath != null && _user.profileImagePath!.isNotEmpty && !kIsWeb)
                                        ? DecorationImage(image: FileImage(File(_user.profileImagePath!)), fit: BoxFit.cover)
                                        : null,
                                    border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.3), width: 2),
                                  ),
                                  child: (_user.profileImagePath == null || _user.profileImagePath!.isEmpty)
                                      ? Center(child: Text(tempUser.profileEmoji, style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)))
                                      : null,
                                ),
                                Positioned(
                                  right: 0, bottom: 0,
                                  child: Container(
                                    width: 26, height: 26,
                                    decoration: BoxDecoration(
                                      color: AppTheme.cyan,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isDark ? AppTheme.surface : Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(child: Text('Fotoğraf değiştirmek için dokunun', style: GoogleFonts.inter(color: subColor.withValues(alpha: 0.6), fontSize: 11))),
                        const SizedBox(height: 20),
                        Text('AVATAR',
                            style: GoogleFonts.inter(
                                color: subColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: ['T', 'D', 'A', 'M', 'S', 'K', 'E', 'H']
                              .map((e) => GestureDetector(
                                    onTap: () => setSheetState(() =>
                                        tempUser =
                                            tempUser.copyWith(profileEmoji: e)),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: tempUser.profileEmoji == e
                                            ? const LinearGradient(colors: [
                                                AppTheme.cyan,
                                                AppTheme.neonPink
                                              ])
                                            : null,
                                        color: tempUser.profileEmoji == e
                                            ? null
                                            : (isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.06)
                                                : Colors.black
                                                    .withValues(alpha: 0.04)),
                                        border: Border.all(
                                          color: tempUser.profileEmoji == e
                                              ? AppTheme.cyan
                                                  .withValues(alpha: 0.5)
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(e,
                                            style: GoogleFonts.inter(
                                              color: tempUser.profileEmoji == e
                                                  ? Colors.white
                                                  : textColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            )),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        Text('AD SOYAD',
                            style: GoogleFonts.inter(
                                color: subColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameCtrl,
                          style: GoogleFonts.inter(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                          decoration: _premiumInput(
                              hint: 'İsminizi girin',
                              icon: Icons.person_outline_rounded,
                              isDark: isDark),
                          onChanged: (v) => setSheetState(
                              () => tempUser = tempUser.copyWith(name: v)),
                        ),
                        const SizedBox(height: 20),
                        Text('E-POSTA',
                            style: GoogleFonts.inter(color: subColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.email_outlined, size: 20, color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AuthService.instance.currentUser?.email ?? 'E-posta bulunamadı',
                                  style: GoogleFonts.inter(
                                    color: (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary).withValues(alpha: 0.7),
                                    fontSize: 14, fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Değiştirilemez', style: GoogleFonts.inter(color: subColor.withValues(alpha: 0.5), fontSize: 10)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('HEDEF UZMANLIK DALI',
                            style: GoogleFonts.inter(
                                color: subColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showBranchPicker(
                              ctx, isDark, tempUser.targetBranch, (b) {
                            setSheetState(() =>
                                tempUser = tempUser.copyWith(targetBranch: b));
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 15),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.school_outlined,
                                    size: 20,
                                    color: isDark
                                        ? AppTheme.textSecondary
                                        : AppTheme.lightTextSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tempUser.targetBranch.isEmpty
                                        ? 'Uzmanlık dalı seçin'
                                        : tempUser.targetBranch,
                                    style: GoogleFonts.inter(
                                      color: tempUser.targetBranch.isEmpty
                                          ? subColor.withValues(alpha: 0.5)
                                          : textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 22, color: subColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(24, 12, 24,
                      MediaQuery.of(ctx).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.surface.withValues(alpha: 0.98)
                        : Colors.white.withValues(alpha: 0.98),
                    border: Border(
                      top: BorderSide(
                        color:
                            isDark ? AppTheme.divider : AppTheme.lightDivider,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final nav = Navigator.of(ctx);
                        final updated = tempUser.copyWith(
                          name: nameCtrl.text.trim().isEmpty
                              ? 'KlinDoktor'
                              : nameCtrl.text.trim(),
                        );
                        await _userService.saveUser(updated);
                        await ProgressService().setDailyGoal(updated.dailyGoal);
                        if (mounted) {
                          setState(() => _user = updated);
                          nav.pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text('Kaydet',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  // ── Çıkış Yap ──────────────────────────────────────────────────────────────

  Future<void> _logout(bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Oturumu Kapat',
            style: GoogleFonts.inter(
                color: isDark ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w800)),
        content: Text('Çıkış yapmak istediğinize emin misiniz?',
            style: GoogleFonts.inter(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal', style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('Çıkış', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.instance.signOut();
      final authVm = Provider.of<AuthViewModel>(context, listen: false);
      await authVm.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // ── Verileri Sıfırla Dialog ────────────────────────────────────────────────

  void _showResetDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppTheme.surface : AppTheme.lightSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Verileri Sıfırla',
            style: GoogleFonts.inter(
                color: isDark
                    ? AppTheme.textPrimary
                    : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w800)),
        content: Text(
            'Tüm çalışma verilerin (ilerleme, SRS kartları) kalıcı olarak silinecek. Bu işlem geri alınamaz.',
            style: GoogleFonts.inter(
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary,
                fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal',
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await ProgressService().resetProgress();
              await SpacedRepetitionService().resetAll();
              if (mounted) {
                nav.pop();
                await _load();
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Veriler sıfırlandı'),
                      backgroundColor: AppTheme.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Sıfırla',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Hakkında Sheet ─────────────────────────────────────────────────────────

  void _showAboutSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.surface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('AsisTus',
                style: GoogleFonts.inter(
                    color: isDark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('v1.0.0',
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Text(
              'TUS sınavına hazırlanma sürecinizi SM-2 Spaced Repetition algoritması ile optimize eden akıllı çalışma asistanınız.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 13,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

}

// ── Stat Mini Card ───────────────────────────────────────────────────────────

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatMini({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.25), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Settings Tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.isDark,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ??
        (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (color ?? AppTheme.cyan).withValues(alpha: isDark ? 0.10 : 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? AppTheme.cyan, size: 18),
        ),
        title: Text(label,
            style: GoogleFonts.inter(
                color: tileColor,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        trailing: trailing ??
            Icon(Icons.chevron_right_rounded,
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary,
                size: 20),
      ),
    );
  }
}

