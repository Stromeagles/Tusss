import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/collection_model.dart';
import '../services/collection_service.dart';
import '../theme/app_theme.dart';
import '../services/premium_service.dart';
import 'package:flutter/services.dart';

/// Kart → Klasör ekleme / çıkarma bottom sheet
class AddToCollectionSheet extends StatefulWidget {
  final String cardId;
  final String cardTitle;

  const AddToCollectionSheet({
    super.key,
    required this.cardId,
    required this.cardTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String cardId,
    required String cardTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToCollectionSheet(cardId: cardId, cardTitle: cardTitle),
    );
  }

  @override
  State<AddToCollectionSheet> createState() => _AddToCollectionSheetState();
}

class _AddToCollectionSheetState extends State<AddToCollectionSheet> {
  final _service = CollectionService();
  bool _creating = false;
  bool _isPremium = false;
  final _nameCtrl = TextEditingController();
  String _selectedEmoji = '📚';
  int _selectedColor = const Color(0xFF00D4FF).toARGB32();

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    final premium = await PremiumService().isPremium();
    if (mounted) setState(() => _isPremium = premium);
  }

  void _showPremiumGate(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF12161E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFA371F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              'Klasörleme Premium Özellik',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kendi klasörlerini oluşturmak ve\nkartları düzenlemek için Premium üye ol.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 12),
            _PremiumFeatureRow(icon: Icons.folder_special_rounded, text: 'Sınırsız klasör oluştur'),
            _PremiumFeatureRow(icon: Icons.add_card_rounded, text: 'Her karta not ve etiket ekle'),
            _PremiumFeatureRow(icon: Icons.sync_rounded, text: 'Tüm cihazlarda klasör senkronizasyonu'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.star_rounded, size: 18),
                label: Text(
                  "Premium'a Geç",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final collections = _service.collections;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.surface.withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: subColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.neonPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.folder_rounded,
                          color: AppTheme.neonPurple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Klasöre Ekle',
                              style: GoogleFonts.inter(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          Text(widget.cardTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  color: subColor, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: subColor, size: 20),
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 24,
                  color: isDark ? AppTheme.divider : AppTheme.lightDivider),

              // Klasörler listesi
              Flexible(
                child: collections.isEmpty && !_creating
                    ? _buildEmptyState(subColor)
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: collections.length + (_creating ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          if (_creating && i == collections.length) {
                            return _buildCreateForm(isDark, textColor, subColor);
                          }
                          return _buildCollectionTile(
                              collections[i], isDark, textColor, subColor);
                        },
                      ),
              ),

              // Alt butonlar
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
                child: _creating
                    ? const SizedBox.shrink()
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (!_isPremium) {
                              _showPremiumGate(context);
                              return;
                            }
                            setState(() => _creating = true);
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text('Yeni Klasör Oluştur',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.neonPurple,
                            side: BorderSide(
                                color: AppTheme.neonPurple.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionTile(CardCollection col, bool isDark, Color textColor,
      Color subColor) {
    final inCollection = _service.isCardInCollection(col.id, widget.cardId);
    return GestureDetector(
      onTap: () async {
        if (!_isPremium) {
          _showPremiumGate(context);
          return;
        }
        await _service.toggleCard(col.id, widget.cardId);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: inCollection
              ? Color(col.colorValue).withValues(alpha: isDark ? 0.15 : 0.10)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.025)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: inCollection
                ? Color(col.colorValue).withValues(alpha: 0.35)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            Text(col.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(col.name,
                      style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text('${col.cardIds.length} kart',
                      style:
                          GoogleFonts.inter(color: subColor, fontSize: 11)),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: inCollection
                  ? Icon(Icons.check_circle_rounded,
                      key: const ValueKey('checked'),
                      color: Color(col.colorValue),
                      size: 22)
                  : Icon(Icons.add_circle_outline_rounded,
                      key: const ValueKey('unchecked'),
                      color: subColor.withValues(alpha: 0.5),
                      size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm(bool isDark, Color textColor, Color subColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.neonPurple.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.neonPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Emoji seçici
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: CollectionPresets.emojis.length,
              itemBuilder: (_, i) {
                final e = CollectionPresets.emojis[i];
                final selected = e == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.neonPurple.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppTheme.neonPurple.withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                        child: Text(e,
                            style: const TextStyle(fontSize: 20))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Renk seçici
          SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: CollectionPresets.colors.length,
              itemBuilder: (_, i) {
                final c = CollectionPresets.colors[i];
                final selected = c.toARGB32() == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c.toARGB32()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28, height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Ad alanı
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.inter(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Klasör adı (örn: Zor Bakteriler)',
              hintStyle: GoogleFonts.inter(
                  color: subColor.withValues(alpha: 0.5), fontSize: 13),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _creating = false;
                    _nameCtrl.clear();
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: subColor,
                    side:
                        BorderSide(color: subColor.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('İptal',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nameCtrl.text.trim().isEmpty
                      ? null
                      : () async {
                          final col = await _service.createCollection(
                            _nameCtrl.text.trim(),
                            _selectedEmoji,
                            _selectedColor,
                          );
                          await _service.addCard(col.id, widget.cardId);
                          setState(() {
                            _creating = false;
                            _nameCtrl.clear();
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Oluştur & Ekle',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color subColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded,
              color: subColor.withValues(alpha: 0.3), size: 40),
          const SizedBox(height: 10),
          Text('Henüz klasör yok',
              style: GoogleFonts.inter(
                  color: subColor, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Kartları organize etmek için klasör oluştur.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: subColor.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PremiumFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PremiumFeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFFD700), size: 14),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
