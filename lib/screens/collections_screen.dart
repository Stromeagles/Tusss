import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/collection_model.dart';
import '../services/collection_service.dart';
import '../theme/app_theme.dart';
import 'collection_detail_screen.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final _service = CollectionService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_rebuild);
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collections = _service.collections;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF1A0A2E), Color(0xFF0F172A)]
                : const [Color(0xFFEDF3FF), Color(0xFFE8EAFF), Color(0xFFF0F5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: collections.isEmpty
                  ? _buildEmpty(isDark)
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                          16, 12, 16,
                          MediaQuery.of(context).padding.bottom + 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: collections.length,
                      itemBuilder: (_, i) =>
                          _buildCollectionCard(collections[i], isDark, i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: textColor, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Klasörlerim',
                      style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                  Text(
                      '${_service.collections.length} klasör · ${_service.totalCards} kart',
                      style: GoogleFonts.inter(
                          color: isDark
                              ? AppTheme.textSecondary
                              : AppTheme.lightTextSecondary,
                          fontSize: 12)),
                ],
              ),
            ),
            // Yeni klasör
            GestureDetector(
              onTap: () => _showCreateDialog(isDark),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.neonPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.neonPurple.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppTheme.neonPurple, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard(
      CardCollection col, bool isDark, int index) {
    final color = col.color;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollectionDetailScreen(collection: col),
          ),
        );
      },
      onLongPress: () => _showEditDialog(col, isDark),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.10)
                  : color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 18),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(col.emoji,
                        style: const TextStyle(fontSize: 28)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${col.cardIds.length}',
                          style: GoogleFonts.inter(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const Spacer(),
                Text(col.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: isDark
                            ? AppTheme.textPrimary
                            : AppTheme.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('${col.cardIds.length} kart',
                    style: GoogleFonts.inter(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                        fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 60), duration: 350.ms)
        .slideY(begin: 0.08, end: 0);
  }

  Widget _buildEmpty(bool isDark) {
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.neonPurple.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_rounded,
                  color: AppTheme.neonPurple, size: 48),
            ),
            const SizedBox(height: 20),
            Text('Klasörün yok',
                style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Flashcard ve vaka sorularını organize etmek için klasörler oluştur.\nÖrn: "Zor Bakteriler", "Sınav Öncesi"',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: subColor, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(isDark),
              icon: const Icon(Icons.add_rounded),
              label: Text('İlk Klasörü Oluştur',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(bool isDark) {
    _showCollectionDialog(isDark, null);
  }

  void _showEditDialog(CardCollection col, bool isDark) {
    _showCollectionDialog(isDark, col);
  }

  void _showCollectionDialog(bool isDark, CardCollection? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    String emoji = existing?.emoji ?? '📚';
    int colorVal = existing?.colorValue ??
        const Color(0xFF00D4FF).toARGB32();
    final textColor =
        isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor =
        isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.surface.withValues(alpha: 0.97)
                    : Colors.white.withValues(alpha: 0.97),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null
                        ? 'Yeni Klasör'
                        : 'Klasörü Düzenle',
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  // Emoji seçici
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: CollectionPresets.emojis.length,
                      itemBuilder: (_, i) {
                        final e = CollectionPresets.emojis[i];
                        final sel = e == emoji;
                        return GestureDetector(
                          onTap: () => setLocal(() => emoji = e),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 44,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppTheme.neonPurple
                                      .withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel
                                    ? AppTheme.neonPurple
                                        .withValues(alpha: 0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                                child: Text(e,
                                    style:
                                        const TextStyle(fontSize: 22))),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Renk seçici
                  SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: CollectionPresets.colors.length,
                      itemBuilder: (_, i) {
                        final c = CollectionPresets.colors[i];
                        final sel = c.toARGB32() == colorVal;
                        return GestureDetector(
                          onTap: () => setLocal(() => colorVal = c.toARGB32()),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 32, height: 32,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sel
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                          color: c.withValues(alpha: 0.5),
                                          blurRadius: 10)
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style:
                        GoogleFonts.inter(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Klasör adı...',
                      hintStyle: GoogleFonts.inter(
                          color: subColor.withValues(alpha: 0.5),
                          fontSize: 14),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (existing != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _service
                                  .deleteCollection(existing.id);
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 16),
                            label: Text('Sil',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 13),
                            ),
                          ),
                        ),
                      if (existing != null) const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: nameCtrl.text.trim().isEmpty
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  if (existing == null) {
                                    await _service.createCollection(
                                        nameCtrl.text.trim(),
                                        emoji,
                                        colorVal);
                                  } else {
                                    await _service.renameCollection(
                                        existing.id,
                                        nameCtrl.text.trim(),
                                        emoji,
                                        colorVal);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            existing == null ? 'Oluştur' : 'Kaydet',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
