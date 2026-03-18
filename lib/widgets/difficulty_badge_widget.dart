import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const DifficultyBadge({super.key, required this.difficulty});

  Color get _color {
    switch (difficulty.toLowerCase()) {
      case 'hard':
        return AppTheme.hardColor;
      case 'easy':
        return AppTheme.easyColor;
      default:
        return AppTheme.mediumColor;
    }
  }

  String get _label {
    switch (difficulty.toLowerCase()) {
      case 'hard':
        return 'ZOR';
      case 'easy':
        return 'KOLAY';
      default:
        return 'ORTA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
