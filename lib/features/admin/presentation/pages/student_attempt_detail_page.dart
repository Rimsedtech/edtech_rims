import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/attempt_repository.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/exam_repository.dart';
import 'package:bitwise_academy/shared/domain/repositories/user_repository.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

/// Admin page: per-question answer breakdown for a specific student attempt.
class StudentAttemptDetailPage extends StatefulWidget {
  const StudentAttemptDetailPage({
    super.key,
    required this.userId,
    required this.attemptId,
  });

  final String userId;
  final String attemptId;

  @override
  State<StudentAttemptDetailPage> createState() =>
      _StudentAttemptDetailPageState();
}

class _StudentAttemptDetailPageState extends State<StudentAttemptDetailPage> {
  bool _isLoading = true;
  String? _error;

  AttemptModel? _attempt;
  ExamModel? _exam;
  List<QuestionModel> _questions = [];
  UserEntity? _student;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final attemptRepo = getIt<AttemptRepository>();
    final examRepo = getIt<ExamRepository>();
    final userRepo = getIt<UserRepository>();

    // Step 1: load the user's attempts to find the specific one
    final allAttemptsResult = await attemptRepo.fetchUserAttempts(widget.userId);
    switch (allAttemptsResult) {
      case Failure(:final errorMessage):
        if (mounted) {
          setState(() {
            _error = errorMessage;
            _isLoading = false;
          });
        }
        return;
      case Success(:final data):
        final AttemptModel? found = data
            .where((a) => a.id == widget.attemptId)
            .firstOrNull;
        if (found == null) {
          if (mounted) {
            setState(() {
              _error = 'Attempt not found.';
              _isLoading = false;
            });
          }
          return;
        }
        _attempt = found;
    }

    // Step 2: load exam + questions + user
    final examResult = await examRepo.fetchExamById(_attempt!.examId);
    final userResult = await userRepo.fetchUser(widget.userId);

    // Use saved snapshot if available, otherwise fetch from repo (for old attempts)
    if (_attempt!.questions != null && _attempt!.questions!.isNotEmpty) {
      _questions = _attempt!.questions!;
      _questions.sort((a, b) => a.order.compareTo(b.order));
    } else {
      final questionsResult = await examRepo.fetchQuestions(_attempt!.examId);
      if (questionsResult case Success(:final data)) {
        _questions = data..sort((a, b) => a.order.compareTo(b.order));
      }
    }

    switch (examResult) {
      case Success(:final data):
        _exam = data;
      case Failure():
        break; // Non-fatal — exam might have been deleted
    }

    switch (userResult) {
      case Success(:final data):
        _student = data;
      case Failure():
        break; // non-fatal — use uid as fallback
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () => context.go('/admin/students'),
        ),
        title: Text(
          'ATTEMPT DETAIL',
          style: AppTypography.headlineXs.copyWith(
            color: AppColors.secondaryFixed,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onPrimary),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTypography.adminBody.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _load,
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final AttemptModel attempt = _attempt!;
    final ExamModel? exam = _exam;

    final double pct = attempt.scorePercentage;
    final Color scoreColor = pct >= 70
        ? AppColors.secondary
        : pct >= 50
        ? AppColors.outline
        : AppColors.error;

    final String dateStr = attempt.completedAt != null
        ? _formatDate(attempt.completedAt!)
        : '—';

    final String durationStr = attempt.duration != null
        ? '${attempt.duration!.inMinutes}m ${attempt.duration!.inSeconds % 60}s'
        : '—';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md).copyWith(
        bottom: AppSpacing.xxl,
      ),
      children: [
        // ── Score header card ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(
              left: BorderSide(color: scoreColor, width: 6),
              bottom: BorderSide(color: scoreColor, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student + exam names
              Text(
                _student?.displayName ?? widget.userId,
                style: AppTypography.adminTitle.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                exam?.title ?? attempt.examTitle ?? 
                  (attempt.examId.startsWith('random_mock_') ? 'RANDOM MOCK TEST' : attempt.examId),
                style: AppTypography.adminBody.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Score row
              Row(
                children: [
                  Expanded(
                    child: _ScoreStat(
                      value:
                          '${attempt.score}/${attempt.totalPoints}',
                      label: 'MARKS',
                      color: scoreColor,
                    ),
                  ),
                  Expanded(
                    child: _ScoreStat(
                      value: '${pct.toStringAsFixed(1)}%',
                      label: 'SCORE',
                      color: scoreColor,
                    ),
                  ),
                  Expanded(
                    child: _ScoreStat(
                      value: '${attempt.correctCount}/${_questions.length}',
                      label: 'CORRECT',
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _ScoreStat(
                      value: '${attempt.xpEarned}',
                      label: 'XP',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Progress bar
              ClipRect(
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceDim,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Meta row
              Wrap(
                spacing: AppSpacing.md,
                children: [
                  _MetaChip(icon: Icons.calendar_today, text: dateStr),
                  _MetaChip(icon: Icons.timer, text: durationStr),
                  if (exam != null)
                    _MetaChip(
                      icon: Icons.book,
                      text: exam.subject,
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Section title ──
        Text(
          'QUESTION BREAKDOWN',
          style: AppTypography.headlineXs.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Per-question cards ──
        if (_questions.isEmpty)
          Text(
            'No question data available for this exam.',
            style: AppTypography.adminBody.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          )
        else
          ..._questions.map(
            (q) => _QuestionCard(
              question: q,
              studentAnswer: attempt.answers[q.id]?.toString(),
            ),
          ),
      ],
    );
  }
}

// ── Helper widgets ───────────────────────────────────────────────────────────

class _ScoreStat extends StatelessWidget {
  const _ScoreStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineSm.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.studentAnswer});

  final QuestionModel question;
  final String? studentAnswer;

  @override
  Widget build(BuildContext context) {
    final bool isAnswered = studentAnswer != null && studentAnswer!.isNotEmpty;
    final bool isCorrect = isAnswered &&
        studentAnswer!.trim().toLowerCase() ==
            question.correctAnswer.trim().toLowerCase();

    final Color resultColor =
        isCorrect ? AppColors.secondary : AppColors.error;
    final IconData resultIcon =
        isCorrect ? Icons.check_circle : Icons.cancel;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          left: BorderSide(color: resultColor, width: 4),
          bottom: const BorderSide(color: AppColors.surfaceDim, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Question header ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Q number + type badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      color: AppColors.primary,
                      child: Text(
                        'Q${question.order + 1}',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${question.points} pt${question.points != 1 ? 's' : ''}',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                // Question text
                Expanded(
                  child: Text(
                    question.questionText,
                    style: AppTypography.adminBody.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                // Result icon
                Icon(resultIcon, color: resultColor, size: 22),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.surfaceDim),
            const SizedBox(height: AppSpacing.sm),

            // ── Student's answer ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    'STUDENT:',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    isAnswered ? studentAnswer! : '— not answered —',
                    style: AppTypography.adminBody.copyWith(
                      color: isAnswered ? resultColor : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Correct answer ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    'CORRECT:',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    question.correctAnswer,
                    style: AppTypography.adminBody.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // ── Explanation (if not correct) ──
            if (!isCorrect && question.explanation.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                color: AppColors.surfaceContainerLow,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        question.explanation,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple date formatter — avoids importing `intl`.
String _formatDate(DateTime dt) {
  const List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final String h = dt.hour.toString().padLeft(2, '0');
  final String m = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m';
}
