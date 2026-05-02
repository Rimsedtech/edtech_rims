import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/hp_bar.dart';
import 'package:bitwise_academy/core/widgets/latex_text.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart';

/// Active exam interface where the user answers questions.
///
/// Uses [AttemptBloc] to manage the exam lifecycle:
/// load questions → answer → submit → navigate to results.
class ExamTakingPage extends StatefulWidget {
  final String examId;

  const ExamTakingPage({required this.examId, super.key});

  @override
  State<ExamTakingPage> createState() => _ExamTakingPageState();
}

class _ExamTakingPageState extends State<ExamTakingPage>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  late int _timeLeftSeconds;
  Timer? _timer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer(int durationMinutes) {
    _timeLeftSeconds = durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftSeconds > 0) {
        setState(() => _timeLeftSeconds--);
        if (_timeLeftSeconds < 60 && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        _timer?.cancel();
        _pulseController.stop();
        _submitExam();
      }
    });
  }

  void _submitExam() {
    context.read<AttemptBloc>().add(const SubmitAttemptRequested());
  }

  String get _formattedTime {
    final minutes = (_timeLeftSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_timeLeftSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttemptBloc, AttemptState>(
      listener: (context, state) {
        if (state is AttemptInProgress && _timer == null) {
          _startTimer(state.exam.durationMinutes);
        }
        if (state is AttemptCompleted) {
          context.go('/exams/${widget.examId}/results');
        }
      },
      builder: (context, state) {
        if (state is AttemptLoadInProgress) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'LOADING MISSION...',
                    style: AppTypography.headlineXs.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is AttemptFailure) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 64,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PixelButton(
                      label: 'GO BACK',
                      onPressed: () => context.go('/exams'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is! AttemptInProgress) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: SizedBox.shrink(),
          );
        }

        // ── Active exam UI ──
        final questions = state.questions;
        final totalQuestions = questions.length;
        final currentQuestion = questions[_currentQuestionIndex];
        final progress = (_currentQuestionIndex + 1) / totalQuestions;
        final selectedAnswer = state.selectedAnswers[_currentQuestionIndex];

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: _buildAppBar(),
          body: SafeArea(
            child: Column(
              children: [
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: HpBar(
                    label: 'PROGRESS',
                    value: '${_currentQuestionIndex + 1}/$totalQuestions',
                    progress: progress,
                  ),
                ),

                // Question Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: SingleChildScrollView(
                      key: ValueKey<int>(_currentQuestionIndex),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 4,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Marks badge
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    color: AppColors.tertiary.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: Text(
                                      '${currentQuestion.points} ${currentQuestion.points == 1 ? 'mark' : 'marks'}',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.tertiary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                if (currentQuestion.diagramUrl != null &&
                                    currentQuestion.diagramUrl!.isNotEmpty) ...[
                                  Center(
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxHeight: 250,
                                      ),
                                      margin: const EdgeInsets.only(
                                        bottom: AppSpacing.lg,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.outline,
                                          width: 2,
                                        ),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: currentQuestion.diagramUrl!,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) =>
                                            const Padding(
                                              padding: EdgeInsets.all(
                                                AppSpacing.xl,
                                              ),
                                              child: CircularProgressIndicator(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Padding(
                                              padding: EdgeInsets.all(
                                                AppSpacing.xl,
                                              ),
                                              child: Icon(
                                                Icons.broken_image,
                                                color: AppColors.error,
                                                size: 48,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                                LatexText(
                                  currentQuestion.questionText,
                                  style: AppTypography.bodyXl.copyWith(
                                    color: AppColors.onSurface,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          Text(
                            'SELECT ANSWER:',
                            style: AppTypography.headlineXs.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Build option buttons from live data
                          for (
                            int i = 0;
                            i < currentQuestion.options.length;
                            i++
                          ) ...[
                            _buildOption(
                              context,
                              index: i,
                              text: currentQuestion.options[i],
                              isSelected:
                                  selectedAnswer == currentQuestion.options[i],
                              onTap: () {
                                context.read<AttemptBloc>().add(
                                  AnswerSelected(
                                    questionIndex: _currentQuestionIndex,
                                    selectedOption: currentQuestion.options[i],
                                  ),
                                );
                              },
                            ),
                            if (i < currentQuestion.options.length - 1)
                              const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Navigation Footer
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border(
                      top: BorderSide(color: AppColors.surfaceDim, width: 4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PixelButton(
                          label: 'PREV',
                          isPrimary: false,
                          onPressed: _currentQuestionIndex > 0
                              ? () => setState(() => _currentQuestionIndex--)
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _currentQuestionIndex == totalQuestions - 1
                            ? PixelButton(
                                label: 'FINISH',
                                icon: Icons.flag,
                                onPressed: _submitExam,
                              )
                            : PixelButton(
                                label: 'NEXT',
                                onPressed: () {
                                  setState(() => _currentQuestionIndex++);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final bool isLowTime = _timer != null && _timeLeftSeconds < 60;

    return AppBar(
      backgroundColor: isLowTime ? AppColors.error : AppColors.primary,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Q${_currentQuestionIndex + 1}',
            style: AppTypography.headlineSm.copyWith(
              color: isLowTime ? AppColors.onError : AppColors.onPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.2),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseController.isAnimating
                      ? 1.0 - (_pulseController.value * 0.5)
                      : 1.0,
                  child: child,
                );
              },
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: isLowTime ? AppColors.onError : AppColors.onPrimary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _timer != null ? _formattedTime : '--:--',
                    style: AppTypography.headlineSm.copyWith(
                      color: isLowTime
                          ? AppColors.onError
                          : AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required int index,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.1)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.outlineVariant,
            width: isSelected ? 4 : 2,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary
                    : AppColors.surfaceContainerHigh,
                border: Border.all(
                  color: isSelected
                      ? AppColors.secondary
                      : AppColors.outlineVariant,
                  width: 2,
                ),
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTypography.headlineXs.copyWith(
                    color: isSelected
                        ? AppColors.onSecondary
                        : AppColors.onSurfaceVariant,
                  ),
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: LatexText(
                text,
                style: AppTypography.bodyLg.copyWith(
                  color: isSelected ? AppColors.secondary : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
