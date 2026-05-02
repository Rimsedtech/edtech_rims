import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';

/// A full-screen overlay that celebrates quest completion with confetti,
/// pixel-art animations, and haptic feedback.
class QuestCelebrationOverlay extends StatefulWidget {
  final String questTitle;
  final int xpAwarded;
  final VoidCallback onDismiss;

  const QuestCelebrationOverlay({
    super.key,
    required this.questTitle,
    required this.xpAwarded,
    required this.onDismiss,
  });

  @override
  State<QuestCelebrationOverlay> createState() =>
      _QuestCelebrationOverlayState();
}

class _QuestCelebrationOverlayState extends State<QuestCelebrationOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();

    // Trigger heavy haptic feedback for the achievement "kick"
    HapticFeedback.heavyImpact();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: Stack(
        children: [
          // Confetti cannons on both sides
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 4,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 40,
              minBlastForce: 20,
              gravity: 0.1,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.tertiary,
                Colors.yellow,
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -3 * pi / 4,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 40,
              minBlastForce: 20,
              gravity: 0.1,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.tertiary,
                Colors.yellow,
              ],
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "QUEST CLEAR" Banner
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                            offset: const Offset(8, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        'QUEST CLEAR!',
                        style: AppTypography.headlineMd.copyWith(
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              color: Colors.black,
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .scale(
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.5, 0.5),
                    )
                    .shake(duration: 500.ms, hz: 4)
                    .shimmer(delay: 500.ms, duration: 1.seconds),

                const SizedBox(height: AppSpacing.xxl),

                // Quest Title & Reward
                Column(
                      children: [
                        Text(
                          widget.questTitle.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineSm.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: 32,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '+${widget.xpAwarded} XP',
                              style: AppTypography.headlineMd.copyWith(
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: AppSpacing.xxxl),

                // Press to Continue (Tap anywhere)
                Text(
                      'TAP TO CONTINUE',
                      style: AppTypography.labelLg.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .fadeIn(duration: 800.ms),
              ],
            ),
          ),

          // Invisible dismiss detector
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onDismiss,
              behavior: HitTestBehavior.opaque,
            ),
          ),
        ],
      ),
    );
  }
}
