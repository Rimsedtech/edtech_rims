import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_card.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<LeaderboardBloc>().add(FetchLeaderboardRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
        builder: (context, state) {
          if (state is LeaderboardLoadInProgress) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is LeaderboardLoadFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        border: Border.all(color: AppColors.error, width: 3),
                      ),
                      child: const Icon(
                        Icons.wifi_off,
                        color: AppColors.error,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'FAILED TO LOAD',
                      style: AppTypography.headlineXs.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Could not fetch the leaderboard.\nCheck your connection and try again.',
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    GestureDetector(
                      onTap: () => context.read<LeaderboardBloc>().add(
                        FetchLeaderboardRequested(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          border: Border.all(
                            color: AppColors.primaryContainer,
                            width: 3,
                          ),
                        ),
                        child: Text(
                          'RETRY',
                          style: AppTypography.headlineXs.copyWith(
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is LeaderboardLoadSuccess) {
            return CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final user = state.topUsers[index];
                      return _buildLeaderboardTile(context, user, index + 1);
                    }, childCount: state.topUsers.length),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          64,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        color: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HALL OF FAME',
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.secondaryFixed,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Top players ranked by accuracy and efficiency.',
              style: AppTypography.bodyLg.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile(
    BuildContext context,
    UserEntity user,
    int rank,
  ) {
    Color rankColor = AppColors.primary;
    if (rank == 1) rankColor = Colors.amber;
    if (rank == 2) rankColor = Colors.grey;
    if (rank == 3) rankColor = Colors.brown;

    final authState = context.read<AuthBloc>().state;
    final isCurrentUser =
        authState is AuthAuthenticated && authState.user.uid == user.uid;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PixelCard(
        borderColor: isCurrentUser
            ? AppColors.primary
            : (rank <= 3 ? rankColor : AppColors.outlineVariant),
        backgroundColor: isCurrentUser
            ? AppColors.primaryContainer.withValues(alpha: 0.3)
            : (rank == 1
                  ? Colors.amber.withValues(alpha: 0.05)
                  : AppColors.surfaceContainerLowest),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rankColor,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: AppTypography.headlineXs.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _buildLeaderboardAvatar(user.avatarUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName.toUpperCase(),
                          style: AppTypography.headlineXs.copyWith(
                            color: isCurrentUser ? Colors.white : AppColors.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Text(
                            'YOU',
                            style: AppTypography.labelSm.copyWith(
                              color: Colors.black,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${user.totalExamsTaken} EXAMS TAKEN',
                    style: AppTypography.labelSm.copyWith(
                      color: isCurrentUser ? Colors.white : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${user.totalCorrectAnswers}',
                  style: AppTypography.headlineXs.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'ANSWERS',
                  style: AppTypography.labelSm.copyWith(
                    color: isCurrentUser ? Colors.white : AppColors.onSurfaceVariant,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.surfaceContainerHigh,
        child: Icon(Icons.person, color: AppColors.primary),
      );
    }

    if (avatarUrl.startsWith('http')) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.transparent,
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
      );
    }

    if (avatarUrl.startsWith('file://')) {
      try {
        final path = Uri.parse(avatarUrl).toFilePath();
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.transparent,
          backgroundImage: FileImage(File(path)),
        );
      } catch (e) {
        // Fallback on error
      }
    }

    return const CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.surfaceContainerHigh,
      child: Icon(Icons.person, color: AppColors.primary),
    );
  }
}
