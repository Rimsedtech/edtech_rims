import 'package:flutter/material.dart';
import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_container.dart';

/// Neo-Arcade card with stepped pixel borders.
class PixelCard extends StatefulWidget {
  final Widget child;
  final String? badge;
  final Color? badgeColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color borderColor;
  final double pixelSize;
  final bool showShadow;

  const PixelCard({
    required this.child,
    this.badge,
    this.badgeColor,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor = Colors.black,
    this.pixelSize = 4.0,
    this.showShadow = false,
    super.key,
  });

  @override
  State<PixelCard> createState() => _PixelCardState();
}

class _PixelCardState extends State<PixelCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTap: () {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: widget.onTap != null ? scale : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PixelContainer(
                backgroundColor:
                    widget.backgroundColor ?? AppColors.surfaceContainerLowest,
                borderColor: widget.borderColor,
                pixelSize: widget.pixelSize,
                padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
                child: widget.child,
              ),
              if (widget.badge != null)
                Positioned(
                  top: -8,
                  left: -8,
                  child: PixelContainer(
                    pixelSize: 2.0, // Smaller pixels for the badge
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs / 2,
                    ),
                    backgroundColor: widget.badgeColor ?? AppColors.tertiary,
                    borderColor: widget.borderColor,
                    child: Text(
                      widget.badge!.toUpperCase(),
                      style: AppTypography.headlineXs.copyWith(
                        color: AppColors.onTertiary,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
