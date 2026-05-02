import 'package:flutter/material.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';

/// HP/Mana-style progress bar with segmented "pip" overlay.
///
/// Mimics classic RPG health bars with a gradient fill and
/// visible segments. Used for test completion %, XP progress,
/// average score, and streak tracking.
class HpBar extends StatelessWidget {
  final String label;
  final String value;
  final double progress; // 0.0 - 1.0
  final HpBarVariant variant;

  const HpBar({
    required this.label,
    required this.value,
    required this.progress,
    this.variant = HpBarVariant.primary,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final (
      Color startColor,
      Color endColor,
      Color valueColor,
    ) = switch (variant) {
      HpBarVariant.primary => (
        AppColors.primary,
        AppColors.primaryContainer,
        AppColors.primary,
      ),
      HpBarVariant.secondary => (
        AppColors.secondary,
        AppColors.secondaryFixed,
        AppColors.secondary,
      ),
      HpBarVariant.tertiary => (
        AppColors.tertiary,
        AppColors.onTertiaryContainer,
        AppColors.tertiary,
      ),
    };

    final double clampedProgress = progress.clamp(0.0, 1.0);
    const int pipCount = 10;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary,
            width: AppSpacing.borderThick,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + value row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                value,
                style: AppTypography.headlineXs.copyWith(color: valueColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Bar container
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: clampedProgress),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedProgress, child) {
                    final double fillWidth =
                        constraints.maxWidth * animatedProgress;
                    return Stack(
                      children: [
                        // Gradient fill
                        Container(
                          width: fillWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [startColor, endColor],
                            ),
                          ),
                        ),
                        // Pip overlay
                        Row(
                          children: List<Widget>.generate(pipCount, (int i) {
                            return Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: i < pipCount - 1
                                        ? BorderSide(
                                            color: AppColors.onSurface
                                                .withValues(alpha: 0.1),
                                            width: 2,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Color variant for the HP bar.
enum HpBarVariant { primary, secondary, tertiary }
