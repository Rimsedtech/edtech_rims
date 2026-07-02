import 'dart:async';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/services/notification_service.dart';
import 'package:bitwise_academy/core/widgets/hp_bar.dart';
import 'package:bitwise_academy/core/widgets/latex_text.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart';

/// Active exam interface where the user answers questions.
///
/// Uses [AttemptBloc] to manage the exam lifecycle:
/// load questions → answer → submit → navigate to results.
///
/// ## Session Lock Behaviours
/// Once the exam is active ([AttemptInProgress] state):
///
/// 1. **Timer auto-starts** — begins immediately when state first becomes
///    [AttemptInProgress]; no extra user interaction is required.
///
/// 2. **Back button is locked** — [BackButtonInterceptor] swallows Android
///    hardware back presses and routes them to the submit-confirmation dialog.
///    Per the project's flutter-navigation-rules skill, [PopScope] is NOT used
///    because it fails silently with go_router on Android.
///    Registered with `zIndex: 2` so it always takes priority over the
///    [ShellScaffold]'s interceptor (registered at `zIndex: 1`).
///
/// 3. **Home / app-switcher is detected** — [WidgetsBindingObserver] tracks
///    the app lifecycle. The flag [_wentToBackground] is set **only** on
///    [AppLifecycleState.paused] (not `inactive`) to avoid false positives
///    from notification-panel pulls, incoming call overlays, or system dialogs.
///    When the app returns from background ([resumed]), the submit-confirmation
///    dialog is shown automatically.
///
/// 4. **Submit confirmation dialog** — shown for every exit attempt (back
///    press or foreground-restore). Tapping *No* resumes the session;
///    tapping *Yes* calls [SubmitAttemptRequested] immediately, even if some
///    questions are unanswered.
///
/// The back interceptor and lifecycle observer are registered only for the
/// duration of this widget's lifecycle and are cleaned up in [dispose].
class ExamTakingPage extends StatefulWidget {
  final String examId;

  const ExamTakingPage({required this.examId, super.key});

  @override
  State<ExamTakingPage> createState() => _ExamTakingPageState();
}

class _ExamTakingPageState extends State<ExamTakingPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Exam state ──────────────────────────────────────────────────────────────

  int _currentQuestionIndex = 0;
  late int _timeLeftSeconds;
  Timer? _timer;
  late final AnimationController _pulseController;

  // ── Session lock state ───────────────────────────────────────────────────────

  /// True once the exam is in [AttemptInProgress] — gates all lock logic so
  /// the back button is free on the loading/error screens.
  bool _missionActive = false;

  /// Set to true when [AppLifecycleState.paused] fires during an active
  /// mission. Cleared after the resume-dialog is shown.
  bool _wentToBackground = false;

  /// Prevents stacking multiple dialogs (e.g., rapid back taps).
  bool _dialogShowing = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Register the hardware back-button interceptor.
    // Per flutter-navigation-rules: BackButtonInterceptor is mandatory;
    // PopScope / WillPopScope must NOT be used with go_router.
    //
    // zIndex: 2 ensures this interceptor fires BEFORE the ShellScaffold's
    // interceptor (registered at zIndex: 1), so the exam lock always wins
    // while this page is alive — even though ExamTakingPage sits outside the
    // shell route and both interceptors are simultaneously registered.
    BackButtonInterceptor.add(
      backButtonInterceptor,
      context: context,
      zIndex: 2,
      name: 'examSessionLock',
    );
    
    // Register lifecycle observer for home / app-switcher detection.
    WidgetsBinding.instance.addObserver(this);
    
    // ── Critical: bootstrap timer for the already-current AttemptInProgress ──
    //
    // The BlocConsumer listener (in build()) fires ONLY on state CHANGES after
    // the widget subscribes — it does NOT replay the current state on first
    // mount. The typical flow is:
    //
    //   1. Dashboard dispatches StartRandomMockTestRequested
    //   2. AttemptBloc emits AttemptInProgress  ← stream fires
    //   3. Dashboard's BlocListener calls context.go('/exams/.../take')
    //   4. ExamTakingPage is mounted and subscribes to AttemptBloc
    //   5. AttemptBloc state is ALREADY AttemptInProgress (no new emission)
    //   6. BlocConsumer listener is NEVER called → timer never starts ❌
    //
    // Fix: after the first frame (so context.read is safe), check if the bloc
    // is already in AttemptInProgress and start the timer immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentState = context.read<AttemptBloc>().state;
      if (currentState is AttemptInProgress && _timer == null) {
        setState(() => _missionActive = true);
        _startTimer(currentState);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    // Use removeByName for deterministic clean-up matching the named add() above.
    BackButtonInterceptor.removeByName('examSessionLock');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Timer ────────────────────────────────────────────────────────────────────

  void _startTimer(AttemptInProgress state) {
    int elapsedSeconds = DateTime.now().difference(state.attempt.startedAt).inSeconds;
    if (elapsedSeconds < 0) elapsedSeconds = 0; // Guard against minor client clock drift
    final int totalSeconds = state.exam.durationMinutes * 60;
    _timeLeftSeconds = totalSeconds - elapsedSeconds;
    
    if (_timeLeftSeconds <= 0) {
      _timeLeftSeconds = 0;
      _submitExam();
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftSeconds > 0) {
        setState(() => _timeLeftSeconds--);
        if (_timeLeftSeconds < 60 && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        // Time expired → auto-submit without confirmation.
        timer.cancel();
        _pulseController.stop();
        _submitExam();
      }
    });
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  /// Dispatches the submit event directly.  Called by the timer expiry and
  /// by the confirmation dialog's "Yes" branch.
  void _submitExam() {
    context.read<AttemptBloc>().add(const SubmitAttemptRequested());
  }

  // ── Session lock: back button ─────────────────────────────────────────────

  /// Interceptor registered with [BackButtonInterceptor].
  ///
  /// Returns `true` → event consumed (OS does NOT exit the app).
  /// Returns `false` → event passes through (used before mission starts).
  bool backButtonInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (!_missionActive) {
      // Mission hasn't started yet (loading/error screen) — allow normal back.
      return false;
    }
    // Mission is active — intercept and show the confirmation dialog.
    _showSubmitConfirmationDialog();
    return true; // Swallow the back event.
  }

  // ── Session lock: home / app-switcher ────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_missionActive) return;

    // Only treat a true backgrounding event as "went to background".
    //
    // `inactive` is intentionally excluded here because it fires for many
    // non-background events: incoming call overlay, notification shade pull,
    // system permission dialogs, picture-in-picture entry, etc.  Reacting to
    // `inactive` would cause the submit dialog to appear for completely normal
    // in-session interruptions, which is a bad UX.
    //
    // `paused` fires reliably when the app is fully pushed to the background
    if (state == AppLifecycleState.paused) {
      _wentToBackground = true;
      
      // Schedule a local notification to fire exactly 5 minutes before the exam expires.
      // E.g. If exam is 30 mins, fire at minute 25.
      if (_timeLeftSeconds > 300) {
        final expiryTime = DateTime.now().add(Duration(seconds: _timeLeftSeconds - 300));
        NotificationService().scheduleSessionExpiryNotification(
          id: 999, // Unique ID for exam expiry
          title: '⚠️ Mission Expiring Soon!',
          body: 'Your active exam session will expire in 5 minutes. Tap to resume and submit.',
          scheduledDate: expiryTime,
        );
      }
    }

    if (state == AppLifecycleState.resumed && _wentToBackground) {
      // Cancel the pending notification since user returned
      NotificationService().cancelNotification(999);
      _wentToBackground = false;

      // Recalculate remaining time to handle background/sleep duration correctly
      final currentState = context.read<AttemptBloc>().state;
      if (currentState is AttemptInProgress) {
        final int elapsedSeconds = DateTime.now().difference(currentState.attempt.startedAt).inSeconds;
        final int totalSeconds = currentState.exam.durationMinutes * 60;
        final int newTimeLeft = totalSeconds - elapsedSeconds;
        
        setState(() {
          _timeLeftSeconds = newTimeLeft < 0 ? 0 : newTimeLeft;
        });

        if (_timeLeftSeconds <= 0) {
          _timer?.cancel();
          _pulseController.stop();
          _submitExam();
          return;
        }
      }
      
      // App returned from a true background state — show submit confirmation.
      // Use addPostFrameCallback so the widget tree is fully rebuilt first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showSubmitConfirmationDialog());
      });
    }
  }

  // ── Submit confirmation dialog ────────────────────────────────────────────

  /// Shows the "Do you want to submit your answers?" dialog.
  ///
  /// - **No** → dialog dismissed, mission continues.
  /// - **Yes** → [_submitExam] is called immediately.
  ///
  /// The dialog is non-dismissible (barrierDismissible: false) so the student
  /// cannot tap outside to bypass it.
  Future<void> _showSubmitConfirmationDialog() async {
    // Guard: mission may have ended (timer expiry / rapid double-tap) between
    // the moment this was scheduled and when it actually runs.
    if (_dialogShowing || !mounted || !_missionActive) return;
    _dialogShowing = true;

    // Haptic feedback to signal the intercept.
    unawaited(HapticFeedback.mediumImpact());

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Must explicitly choose Yes or No.
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(
                top: BorderSide(color: AppColors.error, width: 4),
                left: BorderSide(color: AppColors.primary, width: 4),
                right: BorderSide(color: AppColors.primary, width: 4),
                bottom: BorderSide(color: AppColors.primary, width: 4),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ───────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  color: AppColors.error,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'MISSION ALERT',
                        style: AppTypography.headlineXs.copyWith(
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ─────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Do you want to submit\nyour answers?',
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.onSurface,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Unanswered questions will be marked as incorrect.',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Action buttons ───────────────────────────────────
                      Row(
                        children: [
                          // No → stay in mission
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(dialogContext).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  border: Border.all(
                                    color: AppColors.outlineVariant,
                                    width: 3,
                                  ),
                                ),
                                child: Text(
                                  'NO — CONTINUE',
                                  style: AppTypography.headlineXs.copyWith(
                                    color: AppColors.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: AppSpacing.md),

                          // Yes → submit answers
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                _submitExam();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  border: Border.all(
                                    color: AppColors.error,
                                    width: 3,
                                  ),
                                ),
                                child: Text(
                                  'YES — SUBMIT',
                                  style: AppTypography.headlineXs.copyWith(
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
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

    _dialogShowing = false;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _formattedTime {
    final minutes = (_timeLeftSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_timeLeftSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttemptBloc, AttemptState>(
      listener: (context, state) {
        // Auto-start the timer the instant the exam goes into progress.
        // _timer == null guard ensures we start exactly once.
        if (state is AttemptInProgress && _timer == null) {
          setState(() => _missionActive = true);
          _startTimer(state);
        }

        // Mission ended (submitted or timed out) — clear lock flag and navigate.
        if (state is AttemptCompleted) {
          setState(() => _missionActive = false);
          context.go('/exams/${widget.examId}/results');
        }
      },
      builder: (context, state) {
        // ── Loading ─────────────────────────────────────────────────────────
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

        // ── Error ────────────────────────────────────────────────────────────
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
                      onPressed: () => context.go('/'),
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

        // ── Active exam UI ──────────────────────────────────────────────────
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
                                // Guard with dialog — does NOT call _submitExam directly.
                                onPressed: _showSubmitConfirmationDialog,
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

  // ── AppBar ────────────────────────────────────────────────────────────────

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

  // ── Option tile ───────────────────────────────────────────────────────────

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
