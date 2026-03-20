import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 600px'den geniş ekranlar (PC/Tablet) için ortalanmış "mobile-frame" görünümü
        if (constraints.maxWidth > 600) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            color: isDark ? AppTheme.background : AppTheme.lightBackground,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRect(child: child),
              ),
            ),
          );
        }
        // Mobil ekranlar için tam ekran
        return child;
      },
    );
  }
}
