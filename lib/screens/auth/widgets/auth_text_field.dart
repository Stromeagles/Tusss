import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.horizontal = false,
    this.errorText,
    this.suffix,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final String              label;
  final String              hint;
  final IconData            icon;
  final TextEditingController controller;
  final bool                obscureText;
  final bool                horizontal;
  final String?             errorText;
  final Widget?             suffix;
  final ValueChanged<String>? onChanged;
  final TextInputType?      keyboardType;
  final TextInputAction?    textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField>
    with SingleTickerProviderStateMixin {
  // ... (existing helper fields)
  late final FocusNode _focus;
  late final AnimationController _animCtrl;
  late final Animation<double> _borderAnim;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _borderAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focus.hasFocus);
    if (_focus.hasFocus) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    if (widget.horizontal) {
      return _buildHorizontalLayout(hasError);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _isFocused ? AppTheme.cyan : AppTheme.textSecondary,
            ),
          ),
        ),
        _buildField(hasError),
        _buildError(hasError),
      ],
    );
  }

  Widget _buildHorizontalLayout(bool hasError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '${widget.label}:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _isFocused ? AppTheme.cyan : AppTheme.textPrimary,
                ),
              ),
            ),
            Expanded(child: _buildField(hasError)),
          ],
        ),
        if (hasError) Padding(
          padding: const EdgeInsets.only(left: 80),
          child: _buildError(hasError),
        ),
      ],
    );
  }

  Widget _buildError(bool hasError) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: hasError
          ? Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 13, color: AppTheme.error),
                  const SizedBox(width: 4),
                  Text(
                    widget.errorText!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildField(bool hasError) {
    return AnimatedBuilder(
      animation: _borderAnim,
      builder: (context, child) {
        final borderColor = hasError
            ? AppTheme.error
            : Color.lerp(AppTheme.border, AppTheme.cyan, _borderAnim.value)!;
        final glowOpacity = hasError ? 0.0 : _borderAnim.value * 0.30;

        final fieldContainer = Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _isFocused && !hasError ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (glowOpacity > 0) ...[
                BoxShadow(
                  color: AppTheme.cyan.withValues(alpha: glowOpacity),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppTheme.cyan.withValues(alpha: glowOpacity * 0.4),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ],
          ),
          child: child,
        );

        return fieldContainer;
      },
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscureText,
        onChanged: widget.onChanged,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        style: GoogleFonts.inter(
          color: AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: AppTheme.cyan,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 15),
          prefixIcon: Icon(
            widget.icon,
            color: _isFocused ? AppTheme.cyan : AppTheme.textMuted,
            size: 20,
          ),
          suffixIcon: widget.suffix,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          filled: false,
        ),
      ),
    );
  }
}
