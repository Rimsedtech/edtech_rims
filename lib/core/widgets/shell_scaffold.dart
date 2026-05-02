import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tap2exit/tap2exit.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';

/// The main shell scaffold wrapping all authenticated routes.
///
/// Provides the retro top bar and chunky bottom navigation bar
/// consistent with the Neo-Arcade Editorial design system.
///
/// The Double-Tap-to-Exit safeguard lives here (via [Tap2Exit]) because
/// all shell tabs navigate with [context.go], which replaces (not pushes)
/// routes — leaving every tab's back stack empty. Placing the intercept
/// at the shell level protects Home, Quests, Ranks, and Admin uniformly.
class ShellScaffold extends StatelessWidget {
  final Widget child;

  const ShellScaffold({required this.child, super.key});

  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/quests')) return 1;
    if (location.startsWith('/leaderboard')) return 2;
    if (location.startsWith('/admin')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final bool isAdmin =
        authState is AuthAuthenticated && authState.user.isAdmin;
    final int currentIndex = _currentIndex(context);

    final List<_NavItem> items = [
      const _NavItem(icon: Icons.home_outlined, label: 'HERO', route: '/'),
      const _NavItem(
        icon: Icons.bolt_outlined,
        label: 'QUESTS',
        route: '/quests',
      ),
      const _NavItem(
        icon: Icons.emoji_events_outlined,
        label: 'RANKS',
        route: '/leaderboard',
      ),
      if (isAdmin)
        const _NavItem(
          icon: Icons.settings_outlined,
          label: 'CONFIG',
          route: '/admin',
        ),
    ];

    return Tap2Exit(
      message: 'Press back again to exit',
      duration: const Duration(milliseconds: 2000),
      useToast: false,
      snackBarStyle: Tap2ExitSnackBarStyle(
        textStyle: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
        backgroundColor: AppColors.surfaceContainerLow,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2000),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Scaffold(
        body: child,
        bottomNavigationBar: Container(
          height: AppSpacing.bottomNavHeight,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            border: Border(
              top: BorderSide(
                color: AppColors.onSurface,
                width: AppSpacing.borderThick,
              ),
            ),
          ),
          child: Row(
            children: List<Widget>.generate(items.length, (int index) {
              final _NavItem item = items[index];
              // Match based on route to handle conditional rendering correctly
              final bool isActive =
                  currentIndex == _getOriginalIndex(item.route);

              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(item.route),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.secondary
                          : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          color: isActive
                              ? AppColors.secondaryFixed
                              : AppColors.surfaceContainerHighest,
                          size: 28,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.label,
                          style: AppTypography.labelLg.copyWith(
                            color: isActive
                                ? AppColors.secondaryFixed
                                : AppColors.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  int _getOriginalIndex(String route) {
    if (route == '/') return 0;
    if (route.startsWith('/quests')) return 1;
    if (route.startsWith('/leaderboard')) return 2;
    if (route.startsWith('/admin')) return 3;
    return 0;
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
