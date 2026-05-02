import 'package:flutter/material.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';

/// Pre-defined typographic variants specifically tuned for pixel fonts.
enum PixelTextVariant { heading1, heading2, body, caption }

/// A centralized typography widget for pixel-art fonts.
///
/// 8-bit fonts require specific sizing, letter-spacing, and line-heights
/// to remain legible. This widget enforces those rules across the app.
class PixelTypography extends StatelessWidget {
  final String text;
  final PixelTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const PixelTypography(
    this.text, {
    super.key,
    this.variant = PixelTextVariant.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// Retrieves the meticulously tuned text style for the variant.
  TextStyle _getStyle(BuildContext context) {
    // Use AppTypography.headlineSm as the base for pixelated styles
    final baseStyle = AppTypography.headlineSm.copyWith(
      color: color ?? Colors.black,
      height: 1.5,
    );

    switch (variant) {
      case PixelTextVariant.heading1:
        return baseStyle.copyWith(
          fontSize: 24,
          letterSpacing: 2.0,
          fontWeight: FontWeight.bold,
        );
      case PixelTextVariant.heading2:
        return baseStyle.copyWith(
          fontSize: 16,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        );
      case PixelTextVariant.body:
        return baseStyle.copyWith(
          fontSize:
              12, // Pixel fonts generally appear much larger than standard fonts
          letterSpacing: 1.0,
        );
      case PixelTextVariant.caption:
        return baseStyle.copyWith(fontSize: 8, letterSpacing: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _getStyle(context),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
