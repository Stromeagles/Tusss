import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class MotivationWidget extends StatelessWidget {
  final Color accentColor;

  const MotivationWidget({
    super.key,
    required this.accentColor,
  });

  static final List<Map<String, String>> _quotes = [
    {
      'text': 'Başarı, küçük çabaların tekrarıdır.',
      'author': 'Robert Collier'
    },
    {
      'text': 'Bilim insanı olmak istiyorsan, sabırlı olmalısın.',
      'author': 'Prof. Dr. Aziz Sancar'
    },
    {
      'text': 'Başarmak istiyorsan, önce inanmalısın.',
      'author': 'Dr. Mehmet Öz'
    },
    {
      'text': 'Tıp, sadece bilgi değil, sabır ve özveridir.',
      'author': 'Hippokrates'
    },
    {
      'text': 'Her gün biraz daha ileri, her gün biraz daha iyi.',
      'author': 'TUS Asistanı'
    },
    {
      'text': 'Bugün çalıştığın her kart, yarın bir hastaya daha iyi bakman demek.',
      'author': 'TUS Asistanı'
    },
    {
      'text': 'Hedefine ulaşmanın tek yolu, her gün bir adım atmak.',
      'author': 'TUS Asistanı'
    },
    {
      'text': 'Yorulduğunda hatırla: Neden başladığını.',
      'author': 'TUS Asistanı'
    },
    {
      'text': 'Başarı tesadüf değil, disiplindir.',
      'author': 'TUS Asistanı'
    },
    {
      'text': 'Bugün çalıştığın bilgi, yarın kurtaracağın can.',
      'author': 'TUS Asistanı'
    },
  ];

  String get _todayQuote {
    // Günün sözünü belirle (her gün aynı olsun)
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length]['text']!;
  }

  String get _todayAuthor {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length]['author']!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.08),
            accentColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.format_quote_rounded,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bugünün Motivasyonu',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _todayQuote,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '— $_todayAuthor',
                  style: TextStyle(
                    color: accentColor.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic);
  }
}
