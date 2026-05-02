import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/core/widgets/pixel_input.dart';
import 'package:bitwise_academy/features/exam_library/data/repositories/exam_repository.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';

/// Admin: Create Exam form with full Firestore integration and file upload.
class CreateExamPage extends StatefulWidget {
  const CreateExamPage({super.key});

  @override
  State<CreateExamPage> createState() => _CreateExamPageState();
}

class _CreateExamPageState extends State<CreateExamPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController();
  final _groupController = TextEditingController();
  final _durationController = TextEditingController();
  final _xpController = TextEditingController();

  DifficultyTier _selectedDifficulty = DifficultyTier.easy;
  File? _selectedFile;
  bool _isSubmitting = false;

  final _picker = ImagePicker();

  Future<void> _pickFile() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _deployExam() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final subject = _subjectController.text.trim();
    final group = _groupController.text.trim();
    final durationStr = _durationController.text.trim();
    final xpStr = _xpController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      _showSnackBar('Please fill in all required fields.');
      return;
    }

    if (subject.isEmpty) {
      _showSnackBar('Subject is required.');
      return;
    }

    if (group.isEmpty) {
      _showSnackBar('Group is required (e.g. "Group A").');
      return;
    }

    final duration = int.tryParse(durationStr);
    if (duration == null || duration <= 0) {
      _showSnackBar('Duration must be a positive number.');
      return;
    }

    final xp = int.tryParse(xpStr);
    if (xp == null || xp < 0) {
      _showSnackBar('XP reward must be a non-negative number.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('Authentication required.');
      return;
    }

    setState(() => _isSubmitting = true);

    final examRepo = getIt<ExamRepository>();
    final result = await examRepo.createExam(
      title: title,
      description: desc,
      subject: subject,
      group: group,
      difficultyTier: _selectedDifficulty,
      durationMinutes: duration,
      createdBy: currentUser.uid,
      xpReward: xp,
      attachmentFile: _selectedFile,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      switch (result) {
        case Success(:final data):
          _showSnackBar('Exam created! Now add questions.');
          context.go('/admin/exams/${data.id}/questions');
        case Failure(:final exception):
          _showSnackBar('Failed: ${exception.message}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    _groupController.dispose();
    _durationController.dispose();
    _xpController.dispose();
    super.dispose();
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
          'CREATE EXAM',
          style: AppTypography.headlineXs.copyWith(
            color: AppColors.secondaryFixed,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelInput(
              label: 'EXAM_TITLE',
              hintText: 'ENTER EXAM NAME',
              controller: _titleController,
            ),
            const SizedBox(height: AppSpacing.lg),
            PixelInput(
              label: 'DESCRIPTION',
              hintText: 'EXAM DESCRIPTION',
              controller: _descController,
            ),
            const SizedBox(height: AppSpacing.lg),
            PixelInput(
              label: 'SUBJECT',
              hintText: 'e.g. ALGEBRA, TRIGONOMETRY',
              controller: _subjectController,
            ),
            const SizedBox(height: AppSpacing.lg),
            PixelInput(
              label: 'GROUP',
              hintText: 'e.g. GROUP A, GROUP B',
              controller: _groupController,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Duration + XP
            Row(
              children: [
                Expanded(
                  child: PixelInput(
                    label: 'DURATION_MIN',
                    hintText: '30',
                    keyboardType: TextInputType.number,
                    controller: _durationController,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PixelInput(
                    label: 'XP_REWARD',
                    hintText: '100',
                    keyboardType: TextInputType.number,
                    controller: _xpController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Difficulty selector
            Text(
              'DIFFICULTY_TIER',
              style: AppTypography.headlineXs.copyWith(
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: DifficultyTier.values.map((tier) {
                final isActive = tier == _selectedDifficulty;
                final color = _colorForTier(tier);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDifficulty = tier),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: tier != DifficultyTier.values.last
                            ? AppSpacing.sm
                            : 0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? color
                            : AppColors.surfaceContainerHighest,
                        border: Border.all(color: color, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          tier.name.toUpperCase(),
                          style: AppTypography.headlineXs.copyWith(
                            color: isActive ? Colors.white : color,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // File attachment section
            Text(
              'EXAM_ATTACHMENT',
              style: AppTypography.headlineXs.copyWith(
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Optional: Attach an image or document for this exam.',
              style: AppTypography.adminBody.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: _isSubmitting ? null : _pickFile,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppColors.secondary
                        : AppColors.primary,
                    width: 4,
                  ),
                ),
                child: _selectedFile != null
                    ? Stack(
                        children: [
                          Center(
                            child: Image.file(
                              _selectedFile!,
                              fit: BoxFit.contain,
                              height: 120,
                              filterQuality: FilterQuality.none,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: _removeFile,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                color: AppColors.error,
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.attach_file,
                            size: 40,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'TAP TO ATTACH FILE',
                            style: AppTypography.labelLg.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Submit button
            if (_isSubmitting)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else
              PixelButton(
                label: 'DEPLOY EXAM',
                icon: Icons.upload,
                width: double.infinity,
                onPressed: _deployExam,
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Color _colorForTier(DifficultyTier tier) {
    switch (tier) {
      case DifficultyTier.easy:
        return AppColors.secondary;
      case DifficultyTier.medium:
        return AppColors.primary;
      case DifficultyTier.hard:
        return AppColors.tertiary;
      case DifficultyTier.ultraHard:
        return AppColors.tertiaryContainer;
    }
  }
}
