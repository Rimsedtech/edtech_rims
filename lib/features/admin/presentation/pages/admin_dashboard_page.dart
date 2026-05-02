import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/core/widgets/hp_bar.dart';
import 'package:bitwise_academy/features/admin/presentation/cubit/admin_stats_cubit.dart';

/// Admin Dashboard with system overview, exam management, and user stats.
///
/// Uses Space Grotesk for data-dense admin interface per DESIGN.md.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminStatsCubit>(
      create: (_) => getIt<AdminStatsCubit>()..loadStats(),
      child: BlocBuilder<AdminStatsCubit, AdminStatsState>(
        builder: (context, statsState) {
          return Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    color: AppColors.primary,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ADMIN CONSOLE',
                              style: AppTypography.headlineSm.copyWith(
                                color: AppColors.secondaryFixed,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'System Control Panel',
                              style: AppTypography.adminBody.copyWith(
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          color: AppColors.tertiary,
                          child: Text(
                            'ADMIN',
                            style: AppTypography.headlineXs.copyWith(
                              color: AppColors.onTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Quick stats ──
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          statsState.isLoading
                              ? '...'
                              : '${statsState.totalUsers}',
                          'TOTAL USERS',
                          Icons.people,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildStatBox(
                          statsState.isLoading
                              ? '...'
                              : '${statsState.activeExams}',
                          'ACTIVE EXAMS',
                          Icons.quiz,
                          AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildStatBox(
                          '—',
                          'TODAY',
                          Icons.assignment,
                          AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── System health ──
                  const HpBar(
                    label: 'SYSTEM UPTIME',
                    value: '100%',
                    progress: 1.0,
                    variant: HpBarVariant.secondary,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Quick Actions ──
                  Text(
                    'QUICK ACTIONS',
                    style: AppTypography.headlineXs.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Column(
                    children: [
                      PixelButton(
                        label: 'CREATE EXAM',
                        icon: Icons.add,
                        width: double.infinity,
                        onPressed: () => context.go('/admin/create-exam'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PixelButton(
                        label: 'MANAGE EXAMS',
                        icon: Icons.settings,
                        isPrimary: false,
                        width: double.infinity,
                        onPressed: () => context.go('/admin/manage-exams'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PixelButton(
                        label: 'TEST CRASH (FIREBASE)',
                        icon: Icons.bug_report,
                        isPrimary: false,
                        width: double.infinity,
                        backgroundColor: AppColors.error,
                        onPressed: () => FirebaseCrashlytics.instance.crash(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: PixelButton(
                          label: 'UPLOAD PIXEL SKIN',
                          icon: Icons.cloud_upload,
                          onPressed: () => context.go('/admin/upload-skin'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Recent Activity ──
                  Text(
                    'RECENT ACTIVITY',
                    style: AppTypography.headlineXs.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildActivityItem(
                    'System initialized',
                    'Firebase project edtech-3f6fe connected',
                    Icons.check_circle,
                    AppColors.secondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActivityItem(
                    'Security rules deployed',
                    'Firestore rules active for all collections',
                    Icons.shield,
                    AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActivityItem(
                    'Auth providers enabled',
                    'Email/Password + Google Sign-In',
                    Icons.lock_open,
                    AppColors.secondary,
                  ),
                  const SizedBox(height: AppSpacing.xxl + AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatBox(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: color, width: 4),
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTypography.headlineMd.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.adminTitle.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  desc,
                  style: AppTypography.adminBody.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
