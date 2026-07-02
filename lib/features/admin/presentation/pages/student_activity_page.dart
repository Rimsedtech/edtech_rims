import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/features/admin/presentation/cubit/admin_activity_cubit.dart';
import 'package:bitwise_academy/shared/models/attempt_model.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/attempt_repository.dart';

/// Admin page: lists all students with their exam activity summary.
/// Tapping a student expands their individual attempt history.
class StudentActivityPage extends StatefulWidget {
  const StudentActivityPage({super.key});

  @override
  State<StudentActivityPage> createState() => _StudentActivityPageState();
}

class _StudentActivityPageState extends State<StudentActivityPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminActivityCubit>(
      create: (_) => getIt<AdminActivityCubit>()..loadActivity(),
      child: BlocBuilder<AdminActivityCubit, AdminActivityState>(
        builder: (context, state) => Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
              onPressed: () => context.go('/admin'),
            ),
            title: Text(
              'STUDENT ACTIVITY',
              style: AppTypography.headlineXs.copyWith(
                color: AppColors.secondaryFixed,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.onPrimary),
                onPressed: () =>
                    context.read<AdminActivityCubit>().loadActivity(),
              ),
            ],
          ),
          body: state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : state.error != null
              ? _buildError(context, state.error!)
              : _buildContent(context, state),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTypography.adminBody.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () =>
                  context.read<AdminActivityCubit>().loadActivity(),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AdminActivityState state) {
    // Filter students by search query
    final List<UserEntity> filtered = state.users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final String q = _searchQuery.toLowerCase();
      return u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();

    // Sort: most exams taken first
    filtered.sort(
      (a, b) => b.totalExamsTaken.compareTo(a.totalExamsTaken),
    );

    return Column(
      children: [
        // ── Summary bar ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          color: AppColors.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryChip(
                '${state.users.length}',
                'STUDENTS',
                AppColors.secondaryFixed,
              ),
              _buildSummaryChip(
                '${state.totalAttemptsCount}',
                'ATTEMPTS',
                AppColors.secondaryFixed,
              ),
              _buildSummaryChip(
                '${state.todayAttemptsCount}',
                'TODAY',
                AppColors.tertiaryFixed,
              ),
            ],
          ),
        ),

        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _searchController,
            style: AppTypography.adminBody.copyWith(
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Search students...',
              hintStyle: AppTypography.adminBody.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: AppColors.outlineVariant,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: AppColors.outlineVariant,
                  width: 1,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),

        // ── Student list ──
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No students found.',
                    style: AppTypography.adminBody.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ).copyWith(bottom: AppSpacing.xxl),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, i) => _StudentRow(
                    student: filtered[i],
                    exams: state.exams,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineSm.copyWith(color: color),
        ),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

// ── Student row with expandable attempt list ────────────────────────────────

class _StudentRow extends StatefulWidget {
  const _StudentRow({
    required this.student,
    required this.exams,
  });

  final UserEntity student;
  final List<ExamModel> exams;

  @override
  State<_StudentRow> createState() => _StudentRowState();
}

class _StudentRowState extends State<_StudentRow> {
  bool _expanded = false;
  bool _isLoading = false;
  List<AttemptModel> _attempts = [];
  bool _hasFetched = false;

  Future<void> _toggleExpand() async {
    setState(() => _expanded = !_expanded);
    if (_expanded && !_hasFetched) {
      setState(() => _isLoading = true);
      final repo = getIt<AttemptRepository>();
      final result = await repo.fetchUserAttempts(widget.student.uid);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasFetched = true;
          if (result is Success<List<AttemptModel>>) {
            _attempts = result.data
                .where((a) => a.status == AttemptStatus.completed)
                .toList();
          }
        });
      }
    }
  }

  String _examTitleOf(AttemptModel attempt) {
    if (attempt.examTitle != null && attempt.examTitle!.isNotEmpty) {
      return attempt.examTitle!;
    }
    final match = widget.exams.where((e) => e.id == attempt.examId).firstOrNull;
    if (match != null) return match.title;
    if (attempt.examId.startsWith('random_mock_')) return 'RANDOM MOCK TEST';
    return attempt.examId;
  }

  @override
  Widget build(BuildContext context) {
    final UserEntity s = widget.student;
    final Color avatarColor = _colorForName(s.displayName);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 4),
          bottom: BorderSide(color: AppColors.surfaceDim, width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── Header row ──
          InkWell(
            onTap: _toggleExpand,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: avatarColor,
                    child: Text(
                      s.displayName.isNotEmpty
                          ? s.displayName[0].toUpperCase()
                          : '?',
                      style: AppTypography.headlineXs.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Name + email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.displayName,
                          style: AppTypography.adminTitle.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          s.email,
                          style: AppTypography.adminBody.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _badge(
                        '${s.totalExamsTaken} EXAMS',
                        AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded attempt list ──
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.surfaceDim),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_attempts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'No completed attempts yet.',
                  style: AppTypography.adminBody.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._attempts.map(
                (attempt) => _AttemptRow(
                  attempt: attempt,
                  examTitle: _examTitleOf(attempt),
                  studentId: widget.student.uid,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: color.withValues(alpha: 0.12),
      child: Text(
        text,
        style: AppTypography.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _colorForName(String name) {
    final List<Color> palette = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
      AppColors.primaryContainer,
    ];
    if (name.isEmpty) return palette[0];
    return palette[name.codeUnitAt(0) % palette.length];
  }
}

// ── Single attempt row inside the expanded section ─────────────────────────

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({
    required this.attempt,
    required this.examTitle,
    required this.studentId,
  });

  final AttemptModel attempt;
  final String examTitle;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final String dateStr = attempt.completedAt != null
        ? _formatDate(attempt.completedAt!)
        : '—';

    final double pct = attempt.scorePercentage;
    final Color scoreColor = pct >= 70
        ? AppColors.secondary
        : pct >= 50
        ? AppColors.outline
        : AppColors.error;

    return InkWell(
      onTap: () => context.go(
        '/admin/students/$studentId/attempts/${attempt.id}',
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceDim, width: 1),
          ),
          color: AppColors.surfaceContainerLow,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.assignment_turned_in,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    examTitle,
                    style: AppTypography.adminBody.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dateStr,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Score chip
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${attempt.score}/${attempt.totalPoints} pts',
                  style: AppTypography.adminBody.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${pct.toStringAsFixed(0)}%  •  ${attempt.correctCount}✓',
                  style: AppTypography.labelSm.copyWith(color: scoreColor),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
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
