import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/hp_bar.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/core/widgets/pixel_card.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';
import 'package:bitwise_academy/core/widgets/mock_test_config_sheet.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart';

/// Hero Dashboard matching the design mockup.
///
/// Layout:
/// 1. App bar with XP counter
/// 2. Hero section (avatar + daily objective CTA)
/// 3. Stats bento grid (HP bar style)
/// 4. Formula game widget + Active quests

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  /// Tracks the timestamp of the most recent back-press for the
  /// Double-Tap-to-Exit safeguard. Null until the first back press.
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  /// Handles back-press events on the Start Destination.
  ///
  /// First press within a 2000 ms window shows a Snackbar prompt;
  /// a second press within that window exits the app gracefully.
  /// No [Timer] is allocated, so there is no async teardown needed.
  void _handleBackPress(BuildContext context) {
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) >
            const Duration(milliseconds: 2000)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Press back again to exit',
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          backgroundColor: AppColors.surfaceContainerLow,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2000),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      );
    } else {
      // Second tap within threshold — exit gracefully.
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope is restricted to this Start Destination ('/') only.
    // canPop: false intercepts the back gesture without permanently
    // blocking predictive back animations on Android 13+.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) _handleBackPress(context);
      },
      child: BlocBuilder<DashboardCubit, DashboardState>(
      builder: (BuildContext context, DashboardState dashState) {
        if (dashState is DashboardLoading || dashState is DashboardInitial) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (dashState is DashboardError) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FAILED TO LOAD DASHBOARD',
                    style: AppTypography.headlineXs.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    dashState.message,
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final loaded = dashState as DashboardLoaded;
        final user = loaded.user;

        return BlocListener<AttemptBloc, AttemptState>(
          listener: (context, state) {
            if (state is AttemptInProgress &&
                state.exam.id.startsWith('random_mock_')) {
              context.go('/exams/${state.exam.id}/take');
            } else if (state is AttemptFailure) {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  content: PixelCard(
                    showShadow: true,
                    badge: 'NO DATA',
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'NO QUESTIONS FOUND',
                          style: AppTypography.headlineSm.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.message,
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PixelButton(
                          label: 'BACK TO BASE',
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          isPrimary: false,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: _buildAppBar(context, user.xp, isAdmin: user.isAdmin),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // ── Hero Section ──
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) => Transform.translate(
                      offset: Offset(0, 30 * (1 - val)),
                      child: Opacity(opacity: val, child: child),
                    ),
                    child: _buildHeroSection(
                      context,
                      userName: user.displayName,
                      level: user.level,
                      streakDays: user.streakDays,
                      user: user,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Stats HP Bars ──
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) => Transform.translate(
                      offset: Offset(0, 40 * (1 - val)),
                      child: Opacity(opacity: val, child: child),
                    ),
                    child: _buildStatsGrid(
                      user.xp,
                      user.level,
                      loaded.testsCompleted,
                      loaded.averageScore,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Subject Grid + Active Quests ──
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) => Transform.translate(
                      offset: Offset(0, 50 * (1 - val)),
                      child: Opacity(opacity: val, child: child),
                    ),
                    child: _buildBottomSection(context),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
    ),   // end BlocBuilder
    );   // end PopScope
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    int xp, {
    bool isAdmin = false,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: AppSpacing.lg,
          right: AppSpacing.sm,
        ),
        height: 64 + MediaQuery.of(context).padding.top,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.primaryContainer, width: 4),
          ),
          boxShadow: [
            BoxShadow(offset: Offset(4, 4), color: AppColors.shadowTinted),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset('logo/logo.png', height: 32, fit: BoxFit.contain),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'RIMS',
                  style: AppTypography.headlineXs.copyWith(
                    color: AppColors.primaryContainer,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Admin badge
                if (isAdmin)
                  GestureDetector(
                    onTap: () => context.push('/admin'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      margin: const EdgeInsets.only(right: AppSpacing.xs),
                      color: AppColors.secondary,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield,
                            color: AppColors.onSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ADMIN',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.onSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // XP counter
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: xp),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedXp, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 4,
                        vertical: AppSpacing.xs,
                      ),
                      color: AppColors.primaryContainer,
                      child: Text(
                        '$animatedXp XP',
                        style: AppTypography.headlineXs.copyWith(
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    );
                  },
                ),
                // Logout button
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Text(
                          'SIGN OUT?',
                          style: AppTypography.headlineSm.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to log out?',
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: Text(
                              'CANCEL',
                              style: AppTypography.labelLg.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              context.read<AuthBloc>().add(
                                const AuthSignOutRequested(),
                              );
                            },
                            child: Text(
                              'LOGOUT',
                              style: AppTypography.labelLg.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      border: Border.all(
                        color: AppColors.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.power_settings_new,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context, {
    required String userName,
    required int level,
    required int streakDays,
    required UserEntity user,
  }) {
    final bool hasCustomSkin =
        user.avatarUrl != null &&
        (user.avatarUrl!.startsWith('http') ||
            user.avatarUrl!.startsWith('file://'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Avatar / Mascot Panel ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: AppColors.primary, width: 4),
              right: BorderSide(color: AppColors.primary, width: 4),
            ),
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: () => context.go('/store'),
                  child: Container(
                    width: 96,
                    height: 96,
                    padding: hasCustomSkin
                        ? const EdgeInsets.all(8)
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      border: Border.all(
                        color: AppColors.secondaryFixed,
                        width: 4,
                      ),
                    ),
                    child: _buildAvatarImage(user.avatarUrl),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PixelButton(
                label: 'STORE',
                onPressed: () => context.go('/store'),
                isPrimary: false,
              ),
              const SizedBox(height: AppSpacing.md),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'WELCOME BACK,',
                  style: AppTypography.headlineXs.copyWith(
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  userName.toUpperCase(),
                  style: AppTypography.headlineXs.copyWith(
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                color: AppColors.secondaryContainer,
                child: Text(
                  'LVL $level',
                  style: AppTypography.headlineXs.copyWith(
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Daily Objective CTA ──
        PixelCard(
          showShadow: true,
          badge: 'DAILY OBJECTIVE',
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'MASTER THE\nMECHANICS',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.primary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                streakDays > 0
                    ? 'Complete your daily mock test to maintain your $streakDays-day winning streak!'
                    : 'Start your first mock test to begin building your streak!',
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<AttemptBloc, AttemptState>(
                builder: (context, attemptState) {
                  final isLoading = attemptState is AttemptLoadInProgress;
                  return PixelButton(
                    label: isLoading ? 'LOADING...' : 'TAKE MOCK TEST',
                    icon: isLoading ? Icons.hourglass_empty : Icons.bolt,
                    width: double.infinity,
                    onPressed: isLoading
                        ? null
                        : () async {
                            final config = await showMockTestConfigSheet(
                              context,
                            );
                            if (config != null && context.mounted) {
                              context.read<AttemptBloc>().add(
                                StartRandomMockTestRequested(
                                  userId: user.uid,
                                  subject: config.subject,
                                  difficultyTier: config.difficulty,
                                  group: config.group,
                                ),
                              );
                            }
                          },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    int xp,
    int level,
    int testsCompleted,
    double avgScore,
  ) {
    // Compute XP progress within current level (500 XP per level)
    final int xpInLevel = xp % 500;
    final double xpProgress = xpInLevel / 500;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: HpBar(
                label: 'LEVEL PROGRESS',
                value: '$xpInLevel/500 XP',
                progress: xpProgress,
                variant: HpBarVariant.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: HpBar(
                label: 'TESTS COMPLETED',
                value: '$testsCompleted',
                progress: testsCompleted > 0
                    ? (testsCompleted / 10).clamp(0.0, 1.0)
                    : 0,
                variant: HpBarVariant.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: HpBar(
                label: 'AVERAGE SCORE',
                value: '${avgScore.toStringAsFixed(0)}%',
                progress: avgScore / 100,
                variant: HpBarVariant.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Subject Grid ("Formula Game") ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            border: Border(
              bottom: BorderSide(color: Color(0xFF101B34), width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SUBJECTS',
                    style: AppTypography.headlineXs.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const Icon(
                    Icons.videogame_asset,
                    color: AppColors.secondaryFixed,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSubjectTile(Icons.functions, 'MATH'),
                  _buildSubjectTile(Icons.science, 'PHYSICS'),
                  _buildSubjectTile(Icons.biotech, 'CHEM'),
                  _buildSubjectTile(Icons.code, 'CS'),
                  _buildSubjectTile(Icons.history_edu, 'HISTORY'),
                  _buildSubjectTile(Icons.public, 'GEO'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Active Quests ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            border: Border.all(color: AppColors.outlineVariant, width: 2),
            boxShadow: const [
              BoxShadow(offset: Offset(4, 4), color: AppColors.shadowTinted),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.surfaceContainerHighest,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'ACTIVE QUESTS',
                  style: AppTypography.headlineXs.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildQuestItem(
                icon: Icons.workspace_premium,
                title: 'FIRST STEPS',
                desc: 'Complete your first exam',
                iconColor: AppColors.secondary,
                bgColor: AppColors.secondaryContainer,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildQuestItem(
                icon: Icons.history_edu,
                title: 'STREAK STARTER',
                desc: 'Login 3 days in a row',
                iconColor: AppColors.tertiary,
                bgColor: AppColors.tertiaryFixed,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildQuestItem(
                icon: Icons.star,
                title: 'PERFECTIONIST',
                desc: 'Score 100% on any exam',
                iconColor: AppColors.primary,
                bgColor: AppColors.primaryFixed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectTile(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        border: Border.all(color: AppColors.onPrimaryContainer, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: AppColors.onPrimaryContainer),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.headlineXs.copyWith(
              color: AppColors.onPrimaryContainer,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestItem({
    required IconData icon,
    required String title,
    required String desc,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.headlineXs.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                desc,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the avatar image safely, supporting network, local files, and fallbacks.
  Widget _buildAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const Icon(
        Icons.smart_toy,
        size: 48,
        color: AppColors.secondaryFixed,
      );
    }

    if (avatarUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) =>
            const Icon(Icons.broken_image_outlined, color: AppColors.error),
      );
    }

    if (avatarUrl.startsWith('file://')) {
      try {
        final file = File(Uri.parse(avatarUrl).toFilePath());
        return Image.file(
          file,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image_outlined, color: AppColors.error),
        );
      } catch (e) {
        return const Icon(Icons.broken_image_outlined, color: AppColors.error);
      }
    }

    return const Icon(
      Icons.smart_toy,
      size: 48,
      color: AppColors.secondaryFixed,
    );
  }
}
