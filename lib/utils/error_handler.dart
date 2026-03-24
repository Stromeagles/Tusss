import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Merkezi hata yonetimi — Snackbar, Dialog ve Fallback widget'lari.
class ErrorHandler {
  ErrorHandler._();

  /// Kullanici dostu snackbar gosterir.
  static void showSnackbar(
    BuildContext context, {
    required String message,
    bool isError = true,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry();
                },
                child: Text(
                  'Tekrar Dene',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.cyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  /// Offline veya veri yukleme hatasi icin fallback ekrani.
  static Widget buildFallbackScreen({
    required bool isDark,
    String title = 'Veri Yuklenemedi',
    String message = 'Veriler yuklenirken bir sorun olustu. '
        'Onbellekteki verilerle devam edebilir veya tekrar deneyebilirsiniz.',
    VoidCallback? onRetry,
    bool isOffline = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline
                  ? Icons.wifi_off_rounded
                  : Icons.cloud_off_rounded,
              size: 64,
              color: isDark ? AppTheme.textMuted : AppTheme.lightTextSecondary,
            ),
            const SizedBox(height: 20),
            Text(
              isOffline ? 'Cevrimdisi Mod' : title,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isOffline
                  ? 'Internet baglantisi bulunamadi. Onbellekteki verilerle devam edebilirsiniz.'
                  : message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Tekrar Dene',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
