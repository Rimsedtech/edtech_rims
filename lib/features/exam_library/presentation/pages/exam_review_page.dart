import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/latex_text.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';

/// Post-submission review screen.
///
/// Reads [AttemptCompleted] from [AttemptBloc] and renders every question
/// with colour-coded options (green = correct, red = wrong selection) and
/// the written explanation beneath each answer.
class ExamReviewPage extends StatefulWidget {
  final String examId;

  const ExamReviewPage({required this.examId, super.key});

  @override
  State<ExamReviewPage> createState() => _ExamReviewPageState();
}

class _ExamReviewPageState extends State<ExamReviewPage> {
  // Tracks which question cards have their explanation visible.
  final Set<int> _expandedExplanations = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttemptBloc, AttemptState>(
      builder: (context, state) {
        if (state is! AttemptCompleted) {
          // Guard against direct navigation when state is gone.
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: _buildAppBar(context, 'MISSION REVIEW'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 48),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No review data available.',
                    style: AppTypography.bodyLg
                        .copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PixelButton(
                    label: 'RETURN TO BASE',
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          );
        }

        final questions = state.questions;
        final selectedAnswers = state.selectedAnswers;
        final int correct = state.correctCount;
        final int total = state.totalQuestions;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: _buildAppBar(context, 'MISSION REVIEW  $correct/$total'),
          body: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            itemCount: questions.length + 1, // +1 for footer button
            itemBuilder: (context, index) {
              if (index == questions.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xxl,
                  ),
                  child: PixelButton(
                    label: 'RETURN TO BASE',
                    width: double.infinity,
                    icon: Icons.home,
                    onPressed: () => context.go('/'),
                  ),
                );
              }

              final question = questions[index];
              final String? studentAnswer = selectedAnswers[index];
              final bool isCorrect =
                  studentAnswer != null &&
                  studentAnswer == question.correctAnswer;
              final bool isUnanswered = studentAnswer == null;

              return _QuestionReviewCard(
                index: index,
                question: question,
                studentAnswer: studentAnswer,
                isCorrect: isCorrect,
                isUnanswered: isUnanswered,
                isExpanded: _expandedExplanations.contains(index),
                onToggleExplanation: () {
                  setState(() {
                    if (_expandedExplanations.contains(index)) {
                      _expandedExplanations.remove(index);
                    } else {
                      _expandedExplanations.add(index);
                    }
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
        onPressed: () => context.go('/exams/${widget.examId}/results'),
      ),
      title: Text(
        title,
        style: AppTypography.headlineXs.copyWith(color: AppColors.onPrimary),
      ),
    );
  }
}

// ── Question Review Card ──────────────────────────────────────────────────────

class _QuestionReviewCard extends StatelessWidget {
  final int index;
  final QuestionModel question;
  final String? studentAnswer;
  final bool isCorrect;
  final bool isUnanswered;
  final bool isExpanded;
  final VoidCallback onToggleExplanation;

  const _QuestionReviewCard({
    required this.index,
    required this.question,
    required this.studentAnswer,
    required this.isCorrect,
    required this.isUnanswered,
    required this.isExpanded,
    required this.onToggleExplanation,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isUnanswered
        ? AppColors.onSurfaceVariant
        : isCorrect
            ? const Color(0xFF22C55E) // green-500
            : AppColors.error;

    final String statusLabel = isUnanswered
        ? 'SKIPPED'
        : isCorrect
            ? 'CORRECT'
            : 'INCORRECT';

    final IconData statusIcon = isUnanswered
        ? Icons.remove_circle_outline
        : isCorrect
            ? Icons.check_circle
            : Icons.cancel;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          left: BorderSide(color: statusColor, width: 6),
          top: BorderSide(color: AppColors.surfaceDim, width: 2),
          right: BorderSide(color: AppColors.surfaceDim, width: 2),
          bottom: BorderSide(color: AppColors.surfaceDim, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Q number + status badge ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: statusColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Text(
                  'Q${index + 1}',
                  style: AppTypography.headlineXs.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: AppTypography.labelSm.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${question.points} ${question.points == 1 ? 'mark' : 'marks'}',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Diagram (if any) ────────────────────────────────────────
                if (question.diagramUrl != null &&
                    question.diagramUrl!.isNotEmpty) ...[
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      margin:
                          const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.outline,
                          width: 2,
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: question.diagramUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Icon(
                            Icons.broken_image,
                            color: AppColors.error,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Question text ────────────────────────────────────────────
                LatexText(
                  question.questionText,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.onSurface,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Options ──────────────────────────────────────────────────
                ...question.options.asMap().entries.map((entry) {
                  final int i = entry.key;
                  final String option = entry.value;
                  final bool isThisTheCorrect =
                      option == question.correctAnswer;
                  final bool isThisStudentPick = option == studentAnswer;

                  // Priority: correct answer always green; student's wrong
                  // pick is red; everything else is neutral.
                  final Color optionBg;
                  final Color optionBorder;
                  final Color optionText;
                  final Widget? trailingIcon;

                  if (isThisTheCorrect) {
                    optionBg =
                        const Color(0xFF22C55E).withValues(alpha: 0.12);
                    optionBorder = const Color(0xFF22C55E);
                    optionText = const Color(0xFF16A34A);
                    trailingIcon = const Icon(
                      Icons.check_circle,
                      color: Color(0xFF22C55E),
                      size: 18,
                    );
                  } else if (isThisStudentPick && !isThisTheCorrect) {
                    optionBg = AppColors.error.withValues(alpha: 0.1);
                    optionBorder = AppColors.error;
                    optionText = AppColors.error;
                    trailingIcon = const Icon(
                      Icons.cancel,
                      color: AppColors.error,
                      size: 18,
                    );
                  } else {
                    optionBg = Colors.transparent;
                    optionBorder = AppColors.outlineVariant;
                    optionText = AppColors.onSurfaceVariant;
                    trailingIcon = null;
                  }

                  return Container(
                    margin:
                        const EdgeInsets.only(bottom: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: optionBg,
                      border: Border.all(color: optionBorder, width: 2),
                    ),
                    child: Row(
                      children: [
                        // Letter badge
                        Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.only(
                            right: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isThisTheCorrect
                                ? const Color(0xFF22C55E)
                                : isThisStudentPick
                                    ? AppColors.error
                                    : AppColors.surfaceContainerHigh,
                            border: Border.all(
                              color: optionBorder,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: AppTypography.labelSm.copyWith(
                                color: (isThisTheCorrect ||
                                        isThisStudentPick)
                                    ? Colors.white
                                    : AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: LatexText(
                            option,
                            style: AppTypography.bodyMd.copyWith(
                              color: optionText,
                              fontWeight: isThisTheCorrect ||
                                      isThisStudentPick
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          trailingIcon,
                        ],
                      ],
                    ),
                  );
                }),

                // ── Unanswered notice ────────────────────────────────────────
                if (isUnanswered) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.onSurfaceVariant,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'You did not answer this question.',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Explanation toggle ───────────────────────────────────────
                if (question.explanation.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: onToggleExplanation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: Row(
                        children: [
                          Icon(
                            isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            isExpanded
                                ? 'HIDE EXPLANATION'
                                : 'SHOW EXPLANATION',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      color: AppColors.surfaceContainerLow,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'EXPLANATION',
                                style: AppTypography.labelSm.copyWith(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          LatexText(
                            question.explanation,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurface,
                              height: 1.6,
                            ),
                          ),
                          (() {
                            final correctIndex = question.options.indexOf(question.correctAnswer);
                            if (correctIndex != -1) {
                              return Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.md),
                                child: Text(
                                  'Correct Answer: (${String.fromCharCode(65 + correctIndex).toLowerCase()}) ${question.correctAnswer}',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: const Color(0xFF22C55E),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          })(),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
