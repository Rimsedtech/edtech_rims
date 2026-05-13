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
    final Color effectiveColor = color ?? Colors.black;

    switch (variant) {
      case PixelTextVariant.heading1:
        // 24px Press Start 2P — use headlineSm (14px) with a bodyXl-like scale.
        // headlineSm is 14px; the widget previously hardcoded 24px which sits
        // between headlineSm(14) and headlineMd(28). Using headlineMd is the
        // closest named token for a prominent pixel heading.
        return AppTypography.headlineSm.copyWith(
          color: effectiveColor,
          fontSize: 24, // intentional: between scale steps, document exception
          letterSpacing: 2.0,
          fontWeight: FontWeight.bold,
        );
      case PixelTextVariant.heading2:
        return AppTypography.headlineSm.copyWith(
          color: effectiveColor,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        );
      case PixelTextVariant.body:
        return AppTypography.headlineXxs.copyWith(
          color: effectiveColor,
          letterSpacing: 1.0,
        );
      case PixelTextVariant.caption:
        return AppTypography.headlineXxs.copyWith(
          color: effectiveColor,
          letterSpacing: 0.5,
        );
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
