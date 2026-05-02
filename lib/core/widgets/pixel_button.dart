import 'package:flutter/material.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';

/// Defines the visual style of the [PixelButton].
enum PixelButtonType { primary, secondary }

/// A reusable button that implements a "stepped" pixel-art border look.
///
/// Upgraded to be backwards-compatible with the legacy design system while
/// providing a modern pixel-art aesthetic. Supports nullable [onPressed] for
/// disabled states.
class PixelButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color borderColor;
  final Color? textColor;
  final double pixelSize;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;
  final double? width;

  const PixelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.borderColor = Colors.black,
    this.textColor,
    this.pixelSize = 4.0,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
    this.width,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;

  /// Helper to determine if the button is currently non-interactive.
  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  /// Determines the background color based on priority:
  /// 1. Disabled state (Muted grey)
  /// 2. Explicitly provided [backgroundColor]
  /// 3. Primary vs Secondary theme defaults
  Color get _effectiveBackgroundColor {
    if (_isDisabled && !widget.isLoading) return const Color(0xFFD1D1D1);
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    return widget.isPrimary ? const Color(0xFFFFD700) : Colors.white;
  }

  /// Determines the text color based on priority:
  /// 1. Disabled state (Darker grey)
  /// 2. Explicitly provided [textColor]
  /// 3. Default Black
  Color get _effectiveTextColor {
    if (_isDisabled && !widget.isLoading) return const Color(0xFF757575);
    if (widget.textColor != null) return widget.textColor!;
    return Colors.black;
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isDisabled) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isDisabled) {
      setState(() => _isPressed = false);
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    if (!_isDisabled) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The "push down" offset when pressed (disabled during loading or if onPressed is null)
    final double pushOffset = (_isPressed && !_isDisabled)
        ? widget.pixelSize
        : 0.0;

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, color: _effectiveTextColor, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          widget.isLoading ? 'LOADING...' : widget.label.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTypography.labelLg.copyWith(
            color: _effectiveTextColor,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );

    if (widget.width != null) {
      buttonContent = SizedBox(
        width: widget.width! - (widget.pixelSize * 4),
        child: buttonContent,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Transform.translate(
        offset: Offset(0, pushOffset),
        child: Opacity(
          opacity: (_isDisabled && !widget.isLoading) ? 0.6 : 1.0,
          child: Container(
            margin: EdgeInsets.all(widget.pixelSize),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _effectiveBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: widget.borderColor,
                  offset: Offset(-widget.pixelSize, 0),
                ),
                BoxShadow(
                  color: widget.borderColor,
                  offset: Offset(widget.pixelSize, 0),
                ),
                BoxShadow(
                  color: widget.borderColor,
                  offset: Offset(0, -widget.pixelSize),
                ),
                BoxShadow(
                  color: widget.borderColor,
                  offset: Offset(0, widget.pixelSize),
                ),
                // Hide 3D shadow if pressed or disabled
                if (!_isPressed && !_isDisabled)
                  BoxShadow(
                    color: widget.borderColor,
                    offset: Offset(0, widget.pixelSize * 2),
                  ),
              ],
            ),
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}
