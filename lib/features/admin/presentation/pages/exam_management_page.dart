import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/exam_library/data/repositories/exam_repository.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';

/// Admin: Exam management list with live Firestore data and actions.
class ExamManagementPage extends StatefulWidget {
  const ExamManagementPage({super.key});

  @override
  State<ExamManagementPage> createState() => _ExamManagementPageState();
}

class _ExamManagementPageState extends State<ExamManagementPage> {
  List<ExamModel> _exams = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final examRepo = getIt<ExamRepository>();
    final result = await examRepo.fetchAllExams();

    if (mounted) {
      switch (result) {
        case Success(:final data):
          setState(() {
            _exams = data;
            _isLoading = false;
          });
        case Failure(:final exception):
          setState(() {
            _errorMessage = exception.message;
            _isLoading = false;
          });
      }
    }
  }

  List<ExamModel> get _filteredExams {
    if (_selectedFilter == 'ALL') return _exams;
    return _exams
        .where((e) => e.status.name.toUpperCase() == _selectedFilter)
        .toList();
  }

  Future<void> _publishExam(ExamModel exam) async {
    final examRepo = getIt<ExamRepository>();
    final result = await examRepo.publishExam(exam.id);
    if (mounted) {
      switch (result) {
        case Success():
          _showSnackBar('${exam.title} published!');
          await _loadExams();
        case Failure(:final exception):
          _showSnackBar('Error: ${exception.message}');
      }
    }
  }

  Future<void> _archiveExam(ExamModel exam) async {
    final examRepo = getIt<ExamRepository>();
    final result = await examRepo.archiveExam(exam.id);
    if (mounted) {
      switch (result) {
        case Success():
          _showSnackBar('${exam.title} archived.');
          await _loadExams();
        case Failure(:final exception):
          _showSnackBar('Error: ${exception.message}');
      }
    }
  }

  Future<void> _deleteExam(ExamModel exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: Text(
          'DELETE EXAM?',
          style: AppTypography.headlineXs.copyWith(color: AppColors.error),
        ),
        content: Text(
          'This will permanently delete "${exam.title}" and all its questions.',
          style: AppTypography.bodyLg.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final examRepo = getIt<ExamRepository>();
      final result = await examRepo.deleteExam(exam.id);
      if (mounted) {
        switch (result) {
          case Success():
            _showSnackBar('${exam.title} deleted.');
            await _loadExams();
          case Failure(:final exception):
            _showSnackBar('Error: ${exception.message}');
        }
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () => context.go('/admin'),
        ),
        title: Text(
          'MANAGE EXAMS',
          style: AppTypography.headlineXs.copyWith(
            color: AppColors.secondaryFixed,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onPrimary),
            onPressed: _loadExams,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: _loadExams,
                      child: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Filter row
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _buildStatusFilter('ALL'),
                    _buildStatusFilter('DRAFT'),
                    _buildStatusFilter('PUBLISHED'),
                    _buildStatusFilter('ARCHIVED'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Stats row
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: AppColors.surfaceContainerLowest,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('${_exams.length}', 'TOTAL'),
                      _buildMiniStat(
                        '${_exams.where((e) => e.status == ExamStatus.published).length}',
                        'PUBLISHED',
                      ),
                      _buildMiniStat(
                        '${_exams.where((e) => e.status == ExamStatus.draft).length}',
                        'DRAFTS',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Exam list
                if (_filteredExams.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        'No exams found.',
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < _filteredExams.length; i++) ...[
                    _buildExamRow(_filteredExams[i]),
                    if (i < _filteredExams.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineSm.copyWith(color: AppColors.primary),
        ),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(String label) {
    final isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildExamRow(ExamModel exam) {
    final statusColor = switch (exam.status) {
      ExamStatus.published => AppColors.secondary,
      ExamStatus.draft => AppColors.outline,
      ExamStatus.archived => AppColors.surfaceDim,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          left: BorderSide(color: statusColor, width: 6),
          bottom: const BorderSide(color: AppColors.surfaceDim, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: AppTypography.adminTitle.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: 4,
                      children: [
                        Text(
                          exam.subject,
                          style: AppTypography.adminBody.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${exam.questionCount} Questions',
                          style: AppTypography.adminBody.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${exam.durationMinutes} min',
                          style: AppTypography.adminBody.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${exam.xpReward} XP',
                          style: AppTypography.adminBody.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                color: statusColor.withValues(alpha: 0.15),
                child: Text(
                  exam.status.name.toUpperCase(),
                  style: AppTypography.labelSm.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Action buttons
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildActionChip(
                'ADD Q',
                Icons.add,
                AppColors.primary,
                () => context.go('/admin/exams/${exam.id}/questions'),
              ),
              if (exam.status == ExamStatus.draft)
                _buildActionChip(
                  'PUBLISH',
                  Icons.publish,
                  AppColors.secondary,
                  () => _publishExam(exam),
                ),
              if (exam.status == ExamStatus.published)
                _buildActionChip(
                  'ARCHIVE',
                  Icons.archive,
                  AppColors.outline,
                  () => _archiveExam(exam),
                ),
              _buildActionChip(
                'DELETE',
                Icons.delete_outline,
                AppColors.error,
                () => _deleteExam(exam),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(border: Border.all(color: color, width: 2)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
