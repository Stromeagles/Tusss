import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Günlük limit aşıldığında gösterilen Premium paywall ekranı.
class PaywallWidget extends StatelessWidget {
  final String type; // 'flashcard' veya 'soru'
  final int dailyLimit;
  final VoidCallback? onUpgrade;

  const PaywallWidget({
    super.key,
    required this.type,
    this.dailyLimit = 50,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kilit ikonu
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.neonGold.withValues(alpha: 0.2),
                    AppTheme.neonPurple.withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.neonGold.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.lock_rounded,
                color: AppTheme.neonGold,
                size: 44,
              ),
            ),
            const SizedBox(height: 28),

            // Başlık
            Text(
              'Günlük Limitine Ulaştın!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Açıklama
            Text(
              'Bugün $dailyLimit $type çözdün.\nSınırsız erişim için Premium\'a geç!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),

            // Premium özellikleri
            _buildFeatureRow(Icons.all_inclusive_rounded, 'Sınırsız flashcard ve soru'),
            const SizedBox(height: 12),
            _buildFeatureRow(Icons.psychology_rounded, 'AI destekli açıklamalar'),
            const SizedBox(height: 12),
            _buildFeatureRow(Icons.trending_up_rounded, 'Detaylı istatistikler'),
            const SizedBox(height: 12),
            _buildFeatureRow(Icons.workspace_premium_rounded, 'Tüm branşlara tam erişim'),
            const SizedBox(height: 40),

            // Premium butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onUpgrade ?? () => _showPremiumSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.neonGold.withValues(alpha: 0.4),
                ),
                child: Text(
                  'Premium\'a Geç',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Yarın tekrar gel
            Text(
              'veya yarın yeni $dailyLimit hak kazanırsın',
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.neonGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.neonGold, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showPremiumSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
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
            Icon(Icons.workspace_premium_rounded, color: AppTheme.neonGold, size: 48),
            const SizedBox(height: 16),
            Text(
              'Premium Yakında!',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Premium abonelik özelliği yakında aktif olacak.\nŞimdilik günlük limitlerle çalışmaya devam edebilirsin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
