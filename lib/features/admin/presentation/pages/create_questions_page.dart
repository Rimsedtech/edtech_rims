import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/widgets/latex_text.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/core/widgets/pixel_input.dart';
import 'package:bitwise_academy/features/exam_library/data/repositories/exam_repository.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';

/// Admin page for creating MCQ questions with LaTeX support.
///
/// Accessed after creating an exam — allows admins to add multiple
/// questions with LaTeX-rendered text, 4 options (A-D), marks per
/// question, and optional explanations.
class CreateQuestionsPage extends StatefulWidget {
  final String examId;

  const CreateQuestionsPage({required this.examId, super.key});

  @override
  State<CreateQuestionsPage> createState() => _CreateQuestionsPageState();
}

class _CreateQuestionsPageState extends State<CreateQuestionsPage> {
  final _questionTextController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _marksController = TextEditingController(text: '1');
  final _explanationController = TextEditingController();
  final _scrollController = ScrollController();

  int _correctOptionIndex = 0; // 0=A, 1=B, 2=C, 3=D
  bool _isSubmitting = false;
  bool _showPreview = false;
  int? _editingIndex;
  File? _selectedDiagramFile;
  final _picker = ImagePicker();

  /// Questions already added to this exam.
  final List<QuestionModel> _addedQuestions = [];

  List<TextEditingController> get _optionControllers => [
    _optionAController,
    _optionBController,
    _optionCController,
    _optionDController,
  ];

  @override
  void dispose() {
    _questionTextController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _marksController.dispose();
    _explanationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDiagram() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final sizeInBytes = await file.length();
      if (sizeInBytes > 2 * 1024 * 1024) {
        _showSnackBar('Diagram must be smaller than 2MB.');
        return;
      }
      setState(() {
        _selectedDiagramFile = file;
      });
    }
  }

  void _removeDiagram() {
    setState(() {
      _selectedDiagramFile = null;
    });
  }

  void _addQuestion() {
    final questionText = _questionTextController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).toList();
    final marksStr = _marksController.text.trim();
    final explanation = _explanationController.text.trim();

    // Validation
    if (questionText.isEmpty) {
      _showSnackBar('Please enter the question text.');
      return;
    }
    for (int i = 0; i < options.length; i++) {
      if (options[i].isEmpty) {
        _showSnackBar('Please fill in Option ${String.fromCharCode(65 + i)}.');
        return;
      }
    }
    final marks = int.tryParse(marksStr);
    if (marks == null || marks <= 0) {
      _showSnackBar('Marks must be a positive number.');
      return;
    }

    setState(() {
      final newQuestion = QuestionModel(
        id: '', // Temporary ID
        difficultyTier: 'medium',
        questionText: questionText,
        questionType: QuestionType.mcq,
        options: options,
        correctAnswer: options[_correctOptionIndex],
        explanation: explanation,
        points: marks,
        diagramUrl:
            _selectedDiagramFile?.path ??
            (_editingIndex != null
                ? _addedQuestions[_editingIndex!].diagramUrl
                : null),
        order: _editingIndex != null
            ? _addedQuestions[_editingIndex!].order
            : _addedQuestions.length + 1,
      );

      if (_editingIndex != null) {
        _addedQuestions[_editingIndex!] = newQuestion;
        _showSnackBar('Question updated in list!');
        _editingIndex = null;
      } else {
        _addedQuestions.add(newQuestion);
        _showSnackBar('Question added to list!');
      }
      _clearForm();
    });
  }

  void _clearForm() {
    _questionTextController.clear();
    for (final controller in _optionControllers) {
      controller.clear();
    }
    _marksController.text = '1';
    _explanationController.clear();
    setState(() {
      _correctOptionIndex = 0;
      _showPreview = false;
      _editingIndex = null;
      _selectedDiagramFile = null;
    });
  }

  void _editQuestion(int index) {
    final q = _addedQuestions[index];
    setState(() {
      _editingIndex = index;
      _questionTextController.text = q.questionText;
      _optionAController.text = q.options[0];
      _optionBController.text = q.options[1];
      _optionCController.text = q.options[2];
      _optionDController.text = q.options[3];
      _marksController.text = q.points.toString();
      _explanationController.text = q.explanation;
      _correctOptionIndex = q.options.indexOf(q.correctAnswer);
      if (_correctOptionIndex == -1) _correctOptionIndex = 0;
      _showPreview = true;
      if (q.diagramUrl != null && !q.diagramUrl!.startsWith('http')) {
        _selectedDiagramFile = File(q.diagramUrl!);
      } else {
        _selectedDiagramFile = null;
      }
    });
    // Scroll to top to show form
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _removeQuestion(int index) {
    setState(() {
      _addedQuestions.removeAt(index);
    });
    _showSnackBar('Question removed from list.');
  }

  Future<void> _finishExam() async {
    if (_addedQuestions.isEmpty) {
      _showSnackBar('Please add at least one question.');
      return;
    }

    setState(() => _isSubmitting = true);

    final examRepo = getIt<ExamRepository>();

    for (int i = 0; i < _addedQuestions.length; i++) {
      final path = _addedQuestions[i].diagramUrl;
      if (path != null && !path.startsWith('http')) {
        final file = File(path);
        if (file.existsSync()) {
          final uploadResult = await examRepo.uploadExamFile(
            examId: widget.examId,
            file: file,
          );
          if (uploadResult is Success<String>) {
            _addedQuestions[i] = _addedQuestions[i].copyWith(
              diagramUrl: uploadResult.data,
            );
          } else {
            if (mounted) {
              _showSnackBar('Failed to upload diagram for question ${i + 1}');
              setState(() => _isSubmitting = false);
            }
            return;
          }
        }
      }
    }

    final result = await examRepo.addQuestionsBatch(
      examId: widget.examId,
      questions: _addedQuestions,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      switch (result) {
        case Success():
          _showSnackBar('Exam finalized successfully!');
          context.go('/admin/manage-exams');
        case Failure(:final errorMessage):
          _showSnackBar('Failed to finalize: $errorMessage');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  int get _totalMarks => _addedQuestions.fold(0, (sum, q) => sum + q.points);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () => context.go('/admin/manage-exams'),
        ),
        title: Text(
          'ADD QUESTIONS',
          style: AppTypography.headlineXs.copyWith(
            color: AppColors.secondaryFixed,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_addedQuestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  color: AppColors.secondary,
                  child: Text(
                    '${_addedQuestions.length} Q · $_totalMarks pts',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Latex help banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border(
                  left: BorderSide(color: AppColors.tertiary, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LaTeX SUPPORT',
                    style: AppTypography.headlineXs.copyWith(
                      color: AppColors.tertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use \$...\$ for inline math. Example: \$\\frac{1}{2}mv^2\$',
                    style: AppTypography.adminBody.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Use \$\$...\$\$ for display math. Example: \$\$E = mc^2\$\$',
                    style: AppTypography.adminBody.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Question counter ──
            Text(
              'QUESTION ${_addedQuestions.length + 1}',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Question text input ──
            PixelInput(
              label: 'QUESTION_TEXT',
              hintText: 'Enter question (LaTeX supported)',
              controller: _questionTextController,
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Upload Diagram (Optional) ──
            Text(
              'DIAGRAM (OPTIONAL)',
              style: AppTypography.headlineXs.copyWith(
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _pickDiagram,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(
                    color: _selectedDiagramFile != null
                        ? AppColors.secondary
                        : AppColors.primary,
                    width: 4,
                  ),
                ),
                child: _selectedDiagramFile != null
                    ? Stack(
                        children: [
                          Center(
                            child: Image.file(
                              _selectedDiagramFile!,
                              fit: BoxFit.contain,
                              height: 120,
                              filterQuality: FilterQuality.none,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: _removeDiagram,
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
                            Icons.image,
                            size: 40,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'TAP TO ATTACH DIAGRAM',
                            style: AppTypography.labelLg.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Preview toggle ──
            GestureDetector(
              onTap: () => setState(() => _showPreview = !_showPreview),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: _showPreview
                    ? AppColors.secondary.withValues(alpha: 0.1)
                    : AppColors.surfaceContainerLowest,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showPreview ? Icons.visibility : Icons.visibility_off,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _showPreview ? 'HIDE PREVIEW' : 'SHOW PREVIEW',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Live LaTeX preview ──
            if (_showPreview) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildPreviewCard(),
            ],
            const SizedBox(height: AppSpacing.lg),

            // ── MCQ Options (A-D) ──
            Text(
              'OPTIONS',
              style: AppTypography.headlineXs.copyWith(
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (int i = 0; i < 4; i++) ...[
              _buildOptionInput(i),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Marks & Explanation ──
            Row(
              children: [
                Expanded(
                  child: PixelInput(
                    label: 'MARKS',
                    hintText: '1',
                    keyboardType: TextInputType.number,
                    controller: _marksController,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 2,
                          bottom: AppSpacing.sm,
                        ),
                        child: Text(
                          'CORRECT_ANSWER',
                          style: AppTypography.headlineXs.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Option ${String.fromCharCode(65 + _correctOptionIndex)}',
                            style: AppTypography.headlineSm.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            PixelInput(
              label: 'EXPLANATION (OPTIONAL)',
              hintText: 'Why is this the correct answer?',
              controller: _explanationController,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Action Buttons ──
            if (_isSubmitting)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else
              Column(
                children: [
                  PixelButton(
                    label: _editingIndex != null
                        ? 'UPDATE QUESTION'
                        : 'ADD QUESTION',
                    icon: _editingIndex != null ? Icons.edit : Icons.add,
                    width: double.infinity,
                    onPressed: _addQuestion,
                  ),
                  if (_editingIndex != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    PixelButton(
                      label: 'CANCEL EDIT',
                      icon: Icons.close,
                      isPrimary: false,
                      width: double.infinity,
                      onPressed: () {
                        _clearForm();
                        _showSnackBar('Edit cancelled.');
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  PixelButton(
                    label: 'DONE — FINISH EXAM',
                    icon: Icons.check,
                    isPrimary: false,
                    width: double.infinity,
                    onPressed: _addedQuestions.isEmpty ? null : _finishExam,
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.xl),

            // ── Added Questions List ──
            if (_addedQuestions.isNotEmpty) ...[
              Text(
                'ADDED QUESTIONS',
                style: AppTypography.headlineXs.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (int i = 0; i < _addedQuestions.length; i++) ...[
                _buildAddedQuestionCard(i),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  /// Preview card showing rendered LaTeX for question + options.
  Widget _buildPreviewCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.secondary, width: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STUDENT VIEW PREVIEW',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Divider(color: AppColors.surfaceDim, height: 24),
          // Question
          LatexText(
            _questionTextController.text.isEmpty
                ? 'Enter a question above...'
                : _questionTextController.text,
            style: AppTypography.bodyXl.copyWith(
              color: _questionTextController.text.isEmpty
                  ? AppColors.surfaceDim
                  : AppColors.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_selectedDiagramFile != null) ...[
            Center(
              child: Image.file(
                _selectedDiagramFile!,
                fit: BoxFit.contain,
                height: 150,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          // Options
          for (int i = 0; i < 4; i++) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: i == _correctOptionIndex
                    ? AppColors.secondary.withValues(alpha: 0.1)
                    : AppColors.surface,
                border: Border.all(
                  color: i == _correctOptionIndex
                      ? AppColors.secondary
                      : AppColors.outlineVariant,
                  width: i == _correctOptionIndex ? 3 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    color: i == _correctOptionIndex
                        ? AppColors.secondary
                        : AppColors.surfaceContainerHigh,
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + i),
                        style: AppTypography.labelSm.copyWith(
                          color: i == _correctOptionIndex
                              ? AppColors.onSecondary
                              : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: LatexText(
                      _optionControllers[i].text.isEmpty
                          ? '...'
                          : _optionControllers[i].text,
                      style: AppTypography.bodyLg.copyWith(
                        color: _optionControllers[i].text.isEmpty
                            ? AppColors.surfaceDim
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < 3) const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }

  /// Option input with radio selector for correct answer.
  Widget _buildOptionInput(int index) {
    final isCorrect = _correctOptionIndex == index;
    final label = String.fromCharCode(65 + index);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Correct-answer radio
        GestureDetector(
          onTap: () => setState(() => _correctOptionIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCorrect ? AppColors.secondary : Colors.transparent,
              border: Border.all(
                color: isCorrect
                    ? AppColors.secondary
                    : AppColors.outlineVariant,
                width: 3,
              ),
            ),
            child: Center(
              child: isCorrect
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      label,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: PixelInput(
            label: 'OPTION_$label',
            hintText: 'Option $label (LaTeX ok)',
            controller: _optionControllers[index],
          ),
        ),
      ],
    );
  }

  /// Card showing an already-added question.
  Widget _buildAddedQuestionCard(int index) {
    final q = _addedQuestions[index];

    return GestureDetector(
      onTap: () => _editQuestion(index),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            left: BorderSide(color: AppColors.secondary, width: 4),
            bottom: BorderSide(color: AppColors.surfaceDim, width: 2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              color: AppColors.primary,
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LatexText(
                    q.questionText,
                    style: AppTypography.adminTitle.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: AppSpacing.md,
                    children: [
                      Text(
                        '${q.points} marks',
                        style: AppTypography.adminBody.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${q.options.length} options',
                        style: AppTypography.adminBody.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Ans: ${q.correctAnswer.length > 20 ? '${q.correctAnswer.substring(0, 20)}...' : q.correctAnswer}',
                        style: AppTypography.adminBody.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (q.diagramUrl != null)
                        Text(
                          'Has Diagram',
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
            GestureDetector(
              onTap: () => _removeQuestion(index),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
