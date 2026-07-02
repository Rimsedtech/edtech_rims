import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/session_recovery_bloc.dart';

class SessionRecoveryPage extends StatefulWidget {
  const SessionRecoveryPage({super.key});

  @override
  State<SessionRecoveryPage> createState() => _SessionRecoveryPageState();
}

class _SessionRecoveryPageState extends State<SessionRecoveryPage> {
  Timer? _countdownTimer;
  int _currentRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    final state = context.read<SessionRecoveryBloc>().state;
    if (state is RecoveryPrompt) {
      _currentRemainingSeconds = state.remainingSeconds;
      _startTimer();
    }
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentRemainingSeconds > 0) {
        setState(() {
          _currentRemainingSeconds--;
        });
      } else {
        timer.cancel();
        context.read<SessionRecoveryBloc>().add(const SubmitSessionRequested(autoSubmitted: true));
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_currentRemainingSeconds / 60).floor().toString().padLeft(2, '0');
    final s = (_currentRemainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onResume(RecoveryPrompt state) {
    // 1. Dispatch ResumeSessionRequested to clear recovery state
    context.read<SessionRecoveryBloc>().add(const ResumeSessionRequested());
    // 2. Navigate to the exam taking page using the examId from the attempt
    Future.microtask(() {
      if (mounted) {
        context.pushReplacement('/exams/${state.attempt.examId}/take');
      }
    });
  }

  void _onSubmit(RecoveryPrompt state) {
    context.read<SessionRecoveryBloc>().add(const SubmitSessionRequested(autoSubmitted: false));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionRecoveryBloc, SessionRecoveryState>(
      listener: (context, state) {
        if (state is RecoveryComplete) {
          // If complete, we might want to let the router handle it (goes to dashboard).
          // For now, let the router do its thing.
        }
      },
      builder: (context, state) {
        if (state is! RecoveryPrompt) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final bool isExpiringSoon = _currentRemainingSeconds <= 300;

        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.8), // dim background
          body: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border.all(
                  color: isExpiringSoon ? AppColors.error : AppColors.primary, 
                  width: 4
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    color: isExpiringSoon ? AppColors.error : AppColors.primary,
                    child: Row(
                      children: [
                        Icon(
                          isExpiringSoon ? Icons.warning_amber_rounded : Icons.assignment_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          isExpiringSoon ? 'SESSION EXPIRING SOON' : 'UNFINISHED MISSION FOUND',
                          style: AppTypography.headlineXs.copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Text(
                          isExpiringSoon 
                            ? 'Your answers will be automatically submitted if time expires.'
                            : 'You have an exam session that was not completed.',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          isExpiringSoon 
                            ? 'Auto-submitting in: $_formattedTime'
                            : 'Session expires in: $_formattedTime',
                          style: AppTypography.headlineSm.copyWith(
                            color: isExpiringSoon ? AppColors.error : AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _onResume(state),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    border: Border.all(color: AppColors.outlineVariant, width: 3),
                                  ),
                                  child: Text(
                                    'RESUME',
                                    style: AppTypography.headlineXs.copyWith(color: AppColors.onSurface),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _onSubmit(state),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: isExpiringSoon ? AppColors.error : AppColors.primary,
                                    border: Border.all(
                                      color: isExpiringSoon ? AppColors.error : AppColors.primary, 
                                      width: 3
                                    ),
                                  ),
                                  child: Text(
                                    isExpiringSoon ? 'SUBMIT NOW' : 'SUBMIT',
                                    style: AppTypography.headlineXs.copyWith(color: Colors.white),
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
          ),
        );
      },
    );
  }
}
