import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_card.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart';
import 'package:bitwise_academy/features/quest/presentation/bloc/quest_bloc.dart';
import 'package:bitwise_academy/shared/models/quest_model.dart';

/// Quest / Achievement page with daily and weekly objectives.
class QuestPage extends StatefulWidget {
  const QuestPage({super.key});

  @override
  State<QuestPage> createState() => _QuestPageState();
}

class _QuestPageState extends State<QuestPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';
    context.read<AttemptBloc>().add(LoadUserAttemptsRequested(userId: userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuestBloc, QuestState>(
      listener: (context, state) {
        // Handle quest XP awarding states
        if (state is QuestXpAwardSuccess) {
          // Sync auth state with the real updated UserEntity from awardXp.
          context.read<AuthBloc>().add(
            AuthUserUpdated(user: state.updatedUser),
          );
        }

        if (state is QuestXpAwardFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to award XP: ${state.error}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<QuestBloc, QuestState>(
        builder: (context, questState) {
          if (questState is QuestLoadInProgress) {
            return const Scaffold(
              backgroundColor: AppColors.surface,
              body: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: AppSpacing.md),
                      Text('Initializing Missions...'),
                    ],
                  ),
                ),
              ),
            );
          }

          if (questState is QuestLoadFailure) {
            return Scaffold(
              backgroundColor: AppColors.surface,
              body: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    margin: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      border: Border.all(color: AppColors.error, width: 4),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'GLITCH IN THE MATRIX',
                          style: AppTypography.headlineSm.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Failed to load quests. Please try again later.\n[ ${questState.message} ]',
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          List<QuestModel> dailyQuests = [];
          List<QuestModel> weeklyQuests = [];

          if (questState is QuestLoadSuccess) {
            dailyQuests = questState.dailyQuests;
            weeklyQuests = questState.weeklyQuests;
          }

          // Wrap with AttemptBloc builder to get test completion count.
          return BlocBuilder<AttemptBloc, AttemptState>(
            builder: (context, attemptState) {
              final authState = context.read<AuthBloc>().state;
              final int streakDays = authState is AuthAuthenticated
                  ? authState.user.streakDays
                  : 0;
              final int testsCompleted = attemptState is UserAttemptsLoaded
                  ? attemptState.totalCompleted
                  : 0;

              final int completedQuests =
                  _computeCompletions(dailyQuests, streakDays, testsCompleted) +
                  _computeCompletions(weeklyQuests, streakDays, testsCompleted);
              final int totalQuests = dailyQuests.length + weeklyQuests.length;

              // Detect newly completed quests and auto-award XP.
              final Set<String> currentlyCompletedQuestIds = {};
              final allQuests = [...dailyQuests, ...weeklyQuests];

              for (final quest in allQuests) {
                int currentProgress = 0;
                final title = quest.title.toLowerCase();
                if (title.contains('login') || title.contains('streak')) {
                  currentProgress = streakDays;
                } else if (title.contains('test') ||
                    title.contains('exam') ||
                    title.contains('scholar')) {
                  currentProgress = testsCompleted;
                }
                if (currentProgress >= quest.targetValue) {
                  currentlyCompletedQuestIds.add(quest.id);
                }
              }

              final Set<String> previouslyCompletedQuestIds =
                  questState is QuestLoadSuccess
                  ? questState.completedQuestIds
                  : {};

              final newlyCompletedQuestIds = currentlyCompletedQuestIds
                  .difference(previouslyCompletedQuestIds);

              for (final questId in newlyCompletedQuestIds) {
                QuestModel? quest;
                for (final q in allQuests) {
                  if (q.id == questId) {
                    quest = q;
                    break;
                  }
                }
                if (quest != null && authState is AuthAuthenticated) {
                  // Light impact for the moment of completion discovery
                  HapticFeedback.lightImpact();
                  context.read<QuestBloc>().add(
                    AwardQuestXp(
                      uid: authState.user.uid,
                      questId: quest.id,
                      xpAmount: quest.xpReward,
                    ),
                  );
                }
              }

              return Scaffold(
                backgroundColor: AppColors.surface,
                body: SafeArea(
                  child: CustomScrollView(
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          color: AppColors.primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'QUEST LOG',
                                    style: AppTypography.headlineSm.copyWith(
                                      color: AppColors.secondaryFixed,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.xs,
                                    ),
                                    color: AppColors.secondaryContainer,
                                    child: Text(
                                      '$completedQuests/$totalQuests COMPLETE',
                                      style: AppTypography.headlineXs.copyWith(
                                        color: AppColors.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Complete objectives to earn bonus XP and unlock achievements.',
                                style: AppTypography.bodyLg.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Daily Quests ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            'DAILY MISSIONS',
                            style: AppTypography.headlineXs.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      if (dailyQuests.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              'No daily missions available.',
                              style: AppTypography.bodyLg.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _buildLiveQuestCard(
                                  quest: dailyQuests[index],
                                  color: AppColors.secondary,
                                  streakDays: streakDays,
                                  testsCompleted: testsCompleted,
                                ),
                              );
                            }, childCount: dailyQuests.length),
                          ),
                        ),

                      // ── Weekly Quests ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.xl,
                            AppSpacing.md,
                            AppSpacing.md,
                          ),
                          child: Text(
                            'WEEKLY CAMPAIGNS',
                            style: AppTypography.headlineXs.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      if (weeklyQuests.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              'No weekly campaigns available.',
                              style: AppTypography.bodyLg.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _buildLiveQuestCard(
                                  quest: weeklyQuests[index],
                                  color: AppColors.tertiary,
                                  streakDays: streakDays,
                                  testsCompleted: testsCompleted,
                                ),
                              );
                            }, childCount: weeklyQuests.length),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xxl),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _computeCompletions(
    List<QuestModel> quests,
    int streakDays,
    int testsCompleted,
  ) {
    int completed = 0;
    for (final quest in quests) {
      final title = quest.title.toLowerCase();
      int currentProgress = 0;
      if (title.contains('login') || title.contains('streak')) {
        currentProgress = streakDays;
      } else if (title.contains('test') ||
          title.contains('exam') ||
          title.contains('scholar')) {
        currentProgress = testsCompleted;
      }
      if (currentProgress >= quest.targetValue) {
        completed++;
      }
    }
    return completed;
  }

  Widget _buildLiveQuestCard({
    required QuestModel quest,
    required Color color,
    required int streakDays,
    required int testsCompleted,
  }) {
    // Basic heuristic to determine progress based on title text
    int currentProgress = 0;
    final title = quest.title.toLowerCase();

    if (title.contains('login') || title.contains('streak')) {
      currentProgress = streakDays;
    } else if (title.contains('test') ||
        title.contains('exam') ||
        title.contains('scholar')) {
      currentProgress = testsCompleted;
    }

    final double rawProgress = quest.targetValue > 0
        ? currentProgress / quest.targetValue
        : 0;
    final double progress = rawProgress.clamp(0.0, 1.0);
    final bool isCompleted = progress >= 1.0;

    // Map icon string to actual IconData
    IconData iconData = Icons.star;
    if (quest.iconName == 'bolt') iconData = Icons.bolt;
    if (quest.iconName == 'check_circle') iconData = Icons.check_circle;
    if (quest.iconName == 'quiz') iconData = Icons.quiz;
    if (quest.iconName == 'local_fire_department') {
      iconData = Icons.local_fire_department;
    }
    if (quest.iconName == 'school') iconData = Icons.school;

    return PixelCard(
          borderColor: isCompleted ? color : AppColors.primary,
          backgroundColor: isCompleted
              ? color.withValues(alpha: 0.1)
              : AppColors.surfaceContainerLowest,
          badge: isCompleted ? 'DONE' : null,
          badgeColor: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? color
                          : AppColors.surfaceContainerHigh,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : iconData,
                      color: isCompleted ? Colors.white : color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style: AppTypography.headlineXs.copyWith(
                            color: isCompleted ? color : AppColors.onSurface,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          quest.description,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    color: AppColors.secondaryContainer,
                    child: Text(
                      '+${quest.xpReward} XP',
                      style: AppTypography.headlineXxs.copyWith(
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),

              // Progress bar
              if (!isCompleted) ...[
                const SizedBox(height: AppSpacing.md),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: AppColors.surfaceContainerHighest,
                    ),
                    // Animated Progress Bar
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: Colors.transparent,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(color: color),
                      ),
                    ).animate().scaleX(
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                      alignment: Alignment.centerLeft,
                      begin: 0,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }
}
