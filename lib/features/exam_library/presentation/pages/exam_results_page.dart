import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart';
import 'package:bitwise_academy/shared/services/user_repository.dart';

/// Exam results screen with score and animated XP reward.
///
/// Reads from [AttemptBloc] state — if the state is [AttemptCompleted],
/// it uses real data. Otherwise it falls back to a summary view
/// and fetches user stats.
class ExamResultsPage extends StatefulWidget {
  final String examId;

  const ExamResultsPage({required this.examId, super.key});

  @override
  State<ExamResultsPage> createState() => _ExamResultsPageState();
}

class _ExamResultsPageState extends State<ExamResultsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _xpAnimController;
  Animation<int>? _xpAnimation;

  // Fallback values if navigated to directly (not from exam-taking flow)
  int _score = 0;
  int _total = 0;
  int _xpEarned = 0;
  bool _didInitAnimation = false;

  @override
  void initState() {
    super.initState();
    _xpAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<AttemptBloc>();
      if (bloc.state is! AttemptCompleted) {
        final authState = context.read<AuthBloc>().state;
        final userId = authState is AuthAuthenticated ? authState.user.uid : '';
        bloc.add(LoadUserAttemptsRequested(userId: userId));
      }
    });
  }

  @override
  void dispose() {
    _xpAnimController.dispose();
    super.dispose();
  }

  Future<void> _awardRewardsOnce(int xpToAward) async {
    if (_didInitAnimation) return; // Prevent double awarding
    _didInitAnimation = true;

    _xpAnimation = IntTween(begin: 0, end: xpToAward).animate(
      CurvedAnimation(parent: _xpAnimController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _xpAnimController.forward();
    });

    // Handle Sandboxed client-side logic: Award XP and Coins.
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final userRepo = getIt<UserRepository>();
      final int coinsToAward = xpToAward ~/ 10;

      await userRepo.awardXp(uid: authState.user.uid, xpAmount: xpToAward);
      final updatedResult = await userRepo.awardCoins(
        uid: authState.user.uid,
        coinsAmount: coinsToAward,
      );

      switch (updatedResult) {
        case Success(:final data):
          if (mounted) {
            context.read<AuthBloc>().add(AuthUserUpdated(user: data));
          }
        case Failure():
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttemptBloc, AttemptState>(
      builder: (context, state) {
        if (state is AttemptCompleted) {
          _score = state.correctCount;
          _total = state.totalQuestions;
          _xpEarned = state.attempt.xpEarned;
          _awardRewardsOnce(_xpEarned);
        } else if (state is UserAttemptsLoaded) {
          // Find the most recent attempt for this exam
          final examAttempts = state.attempts
              .where((a) => a.examId == widget.examId)
              .toList();

          if (examAttempts.isNotEmpty) {
            final latest = examAttempts.first;
            _score = latest.score;
            _total = latest.totalPoints;
            _xpEarned = latest.xpEarned;
            _awardRewardsOnce(_xpEarned);
          }
        }
        return _buildResultsUI();
      },
    );
  }

  Widget _buildResultsUI() {
    final double percentage = _total > 0 ? _score / _total : 0;
    final bool passed = percentage >= 0.6;
    final int coinsEarned = _xpEarned ~/ 10;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MISSION ACCOMPLISHED',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.secondaryFixed,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Score Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(
                    color: passed ? AppColors.secondary : AppColors.error,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(8, 8),
                      color: passed ? AppColors.secondary : AppColors.error,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      passed ? 'VICTORY' : 'DEFEAT',
                      style: AppTypography.displayLg.copyWith(
                        color: passed ? AppColors.secondary : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'FINAL SCORE',
                      style: AppTypography.headlineXs.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_score',
                          style: AppTypography.displayLg.copyWith(
                            color: AppColors.onSurface,
                            fontSize: 72,
                          ),
                        ),
                        Text(
                          '/$_total',
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    const Divider(color: AppColors.surfaceDim, thickness: 2),
                    const SizedBox(height: AppSpacing.xl),

                    // Rewards Section
                    Row(
                      children: [
                        // XP Reward
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'XP REWARD',
                                style: AppTypography.headlineXs.copyWith(
                                  color: AppColors.tertiary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _xpAnimation != null
                                    ? AnimatedBuilder(
                                        animation: _xpAnimation!,
                                        builder: (context, child) {
                                          return Text(
                                            '+${_xpAnimation!.value}',
                                            style: AppTypography.headlineMd
                                                .copyWith(
                                                  color: AppColors.tertiary,
                                                  fontSize: 48,
                                                ),
                                          );
                                        },
                                      )
                                    : Text(
                                        '+$_xpEarned',
                                        style: AppTypography.headlineMd
                                            .copyWith(
                                              color: AppColors.tertiary,
                                              fontSize: 48,
                                            ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        // Coins Reward
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'COINS',
                                style: AppTypography.headlineXs.copyWith(
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '+$coinsEarned',
                                  style: AppTypography.headlineMd.copyWith(
                                    color: Colors.amber,
                                    fontSize: 48,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl * 2),

              PixelButton(
                label: 'RETURN TO BASE',
                width: double.infinity,
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
