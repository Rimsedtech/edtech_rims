import 'package:flutter/material.dart';

/// A retro 8-bit style container with "stepped" corners.
///
/// This widget uses a CustomPainter to draw a crisp, pixelated border
/// around any child widget, ensuring perfect scaling without jagged edges.
class PixelContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double pixelSize;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const PixelContainer({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.black,
    this.pixelSize = 4.0,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: CustomPaint(
        painter: _PixelContainerPainter(
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          pixelSize: pixelSize,
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.all(pixelSize * 4),
          child: child,
        ),
      ),
    );
  }
}

/// CustomPainter that draws the 8-bit border logic.
class _PixelContainerPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double pixelSize;

  _PixelContainerPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.pixelSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final p = pixelSize;

    // 1. Draw Outer Border (Stepped Corners)
    paint.color = borderColor;
    // Main vertical block
    canvas.drawRect(Rect.fromLTWH(p, 0, w - p * 2, h), paint);
    // Main horizontal block
    canvas.drawRect(Rect.fromLTWH(0, p, w, h - p * 2), paint);

    // 2. Draw Inner Background
    paint.color = backgroundColor;
    // Inner horizontal block
    canvas.drawRect(Rect.fromLTWH(p * 2, p, w - p * 4, h - p * 2), paint);
    // Inner vertical block
    canvas.drawRect(Rect.fromLTWH(p, p * 2, w - p * 2, h - p * 4), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelContainerPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.pixelSize != pixelSize;
  }
}
