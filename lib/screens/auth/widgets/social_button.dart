import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SocialButton extends StatefulWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final Future<void> Function()? onTap;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> {
  bool _pressed = false;
  bool _localLoading = false;

  Future<void> _handleTap() async {
    if (widget.onTap == null || _localLoading || widget.isLoading) return;
    setState(() => _localLoading = true);
    try {
      await widget.onTap!();
    } finally {
      if (mounted) setState(() => _localLoading = false);
    }
  }

  bool get _showLoading => widget.isLoading || _localLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _showLoading ? null : (_) => setState(() => _pressed = true),
      onTapUp: _showLoading
          ? null
          : (_) {
              setState(() => _pressed = false);
              _handleTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: widget.backgroundColor ??
                    Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border, width: 1),
              ),
              child: _showLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.cyan,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.icon,
                          color: widget.iconColor ?? AppTheme.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.label,
                          style: GoogleFonts.inter(
                            color: widget.textColor ?? AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
