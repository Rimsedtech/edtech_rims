import 'package:flutter/material.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/latex_text.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';

/// Reusable widget that displays a [QuestionModel] with LaTeX support.
///
/// Renders the question text, multiple-choice options with selection state,
/// and an optional explanation/answer-key section (shown after submission).
///
/// Usage:
/// ```dart
/// QuestionView(
///   question: myQuestion,
///   selectedAnswer: userAnswer,
///   onOptionSelected: (option) => handleSelection(option),
/// )
///
/// // After submission — show correct/incorrect + explanation:
/// QuestionView(
///   question: myQuestion,
///   selectedAnswer: userAnswer,
///   showResult: true,
/// )
/// ```
class QuestionView extends StatelessWidget {
  /// The question data to display.
  final QuestionModel question;

  /// The currently selected answer (option text), or null if none selected.
  final String? selectedAnswer;

  /// Called when the user taps an option. Null disables interaction (review mode).
  final ValueChanged<String>? onOptionSelected;

  /// When true, shows correct/incorrect feedback and the explanation.
  /// Typically set to true after the user has submitted the exam.
  final bool showResult;

  /// Optional question number label (e.g., "Q3").
  final int? questionNumber;

  const QuestionView({
    required this.question,
    this.selectedAnswer,
    this.onOptionSelected,
    this.showResult = false,
    this.questionNumber,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Question Card ──
        _buildQuestionCard(),
        const SizedBox(height: AppSpacing.xl),

        // ── Options Header ──
        Text(
          showResult ? 'ANSWERS:' : 'SELECT ANSWER:',
          style: AppTypography.headlineXs.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Option Buttons ──
        for (int i = 0; i < question.options.length; i++) ...[
          _buildOptionTile(index: i, optionText: question.options[i]),
          if (i < question.options.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],

        // ── Explanation (Answer Key) — only after submission ──
        if (showResult && question.explanation.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _buildExplanationCard(),
        ],
      ],
    );
  }

  // ── Question Card ──────────────────────────────────────────────────────

  Widget _buildQuestionCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.primary, width: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: question number + points badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (questionNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    'Q$questionNumber',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                color: AppColors.tertiary.withValues(alpha: 0.15),
                child: Text(
                  '${question.points} ${question.points == 1 ? 'mark' : 'marks'}',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Question text with LaTeX rendering
          LatexText(
            question.questionText,
            style: AppTypography.bodyXl.copyWith(
              color: AppColors.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Option Tile ────────────────────────────────────────────────────────

  Widget _buildOptionTile({required int index, required String optionText}) {
    final bool isSelected = selectedAnswer == optionText;
    final bool isCorrect = optionText == question.correctAnswer;

    // Determine visual state
    Color borderColor;
    Color backgroundColor;
    Color labelColor;
    Color textColor;
    FontWeight textWeight;

    if (showResult) {
      // Post-submission: show correct/incorrect feedback
      if (isCorrect) {
        borderColor = AppColors.secondary;
        backgroundColor = AppColors.secondary.withValues(alpha: 0.1);
        labelColor = AppColors.onSecondary;
        textColor = AppColors.secondary;
        textWeight = FontWeight.w700;
      } else if (isSelected && !isCorrect) {
        borderColor = AppColors.error;
        backgroundColor = AppColors.error.withValues(alpha: 0.08);
        labelColor = AppColors.onError;
        textColor = AppColors.error;
        textWeight = FontWeight.w700;
      } else {
        borderColor = AppColors.outlineVariant;
        backgroundColor = AppColors.surface;
        labelColor = AppColors.onSurfaceVariant;
        textColor = AppColors.onSurfaceVariant;
        textWeight = FontWeight.w400;
      }
    } else {
      // Active state: show selection highlight
      if (isSelected) {
        borderColor = AppColors.secondary;
        backgroundColor = AppColors.secondary.withValues(alpha: 0.1);
        labelColor = AppColors.onSecondary;
        textColor = AppColors.secondary;
        textWeight = FontWeight.w700;
      } else {
        borderColor = AppColors.outlineVariant;
        backgroundColor = AppColors.surface;
        labelColor = AppColors.onSurfaceVariant;
        textColor = AppColors.onSurface;
        textWeight = FontWeight.w400;
      }
    }

    return GestureDetector(
      onTap: showResult ? null : () => onOptionSelected?.call(optionText),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: (isSelected || (showResult && isCorrect)) ? 4 : 2,
          ),
        ),
        child: Row(
          children: [
            // Letter badge (A, B, C, D)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (isSelected || (showResult && isCorrect))
                    ? borderColor
                    : AppColors.surfaceContainerHigh,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTypography.headlineXs.copyWith(color: labelColor),
                  child: Text(String.fromCharCode(65 + index)),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Option text with LaTeX
            Expanded(
              child: LatexText(
                optionText,
                style: AppTypography.bodyLg.copyWith(
                  color: textColor,
                  fontWeight: textWeight,
                ),
              ),
            ),

            // Result icon
            if (showResult && isCorrect)
              const Icon(
                Icons.check_circle,
                color: AppColors.secondary,
                size: 24,
              )
            else if (showResult && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: AppColors.error, size: 24),
          ],
        ),
      ),
    );
  }

  // ── Explanation Card (Answer Key) ──────────────────────────────────────

  Widget _buildExplanationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.secondary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ANSWER KEY',
                style: AppTypography.headlineXs.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LatexText(
            question.explanation,
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
