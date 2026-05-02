import 'package:flutter/material.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_container.dart';

/// A retro-style progress bar with a pixelated border.
class PixelProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String? label;
  final String? valueText;
  final Color? fillColor;
  final Color backgroundColor;
  final Color borderColor;
  final double pixelSize;
  final double height;

  const PixelProgressBar({
    super.key,
    required this.value,
    this.label,
    this.valueText,
    this.fillColor,
    this.backgroundColor = const Color(0xFFF0F0F0),
    this.borderColor = Colors.black,
    this.pixelSize = 4.0,
    this.height = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final double clampedValue = value.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || valueText != null)
          Padding(
            padding: EdgeInsets.only(bottom: pixelSize),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!.toUpperCase(),
                    style: AppTypography.headlineXs.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (valueText != null)
                  Text(valueText!, style: AppTypography.headlineXs),
              ],
            ),
          ),
        PixelContainer(
          padding: EdgeInsets.zero,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          pixelSize: pixelSize,
          child: SizedBox(
            height: height - (pixelSize * 4),
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // The progress fill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: constraints.maxWidth * clampedValue,
                      color: fillColor ?? const Color(0xFF4CAF50),
                    ),
                    // Optional: Segmented segments for more "retro" look
                    Row(
                      children: List.generate(
                        10,
                        (index) => Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: index < 9
                                    ? BorderSide(
                                        color: borderColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        width: 1,
                                      )
                                    : BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
