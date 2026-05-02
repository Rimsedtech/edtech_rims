import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';

/// The main shell scaffold wrapping all authenticated routes.
///
/// Provides the retro top bar and chunky bottom navigation bar
/// consistent with the Neo-Arcade Editorial design system.
///
/// Implements cross-tab chronological history using `_tabHistory`
/// to retrace tabs when the back button is pressed. The `PopScope` handles
/// deep link back navigation first, then tab history, and finally triggers
/// a 2000ms "Double-Tap-to-Exit" safeguard when the user has returned
/// to the root tab.
class ShellScaffold extends StatefulWidget {
  final Widget child;

  const ShellScaffold({required this.child, super.key});

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> {
  /// Tracks chronological bottom navigation tab clicks.
  final List<String> _tabHistory = ['/'];

  /// Stateful timer for the 2000ms exit window.
  Timer? _exitTimer;

  /// True while the first back-press has been received and the timer is live.
  bool _exitPending = false;

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  void _handleFinalBackPress() {
    if (_exitPending) {
      _exitTimer?.cancel();
      SystemNavigator.pop();
    } else {
      setState(() => _exitPending = true);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Press back again to exit',
              style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
            ),
            backgroundColor: AppColors.surfaceContainerLow,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 2000),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
        );
      _exitTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _exitPending = false);
      });
    }
  }

  void _onBottomNavTapped(String route) {
    if (_tabHistory.isEmpty || _tabHistory.last != route) {
      setState(() {
        _tabHistory.add(route);
      });
    }
    context.go(route);
  }

  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/quests')) return 1;
    if (location.startsWith('/leaderboard')) return 2;
    if (location.startsWith('/admin')) return 3;
    return 0;
  }

  int _getOriginalIndex(String route) {
    if (route == '/') return 0;
    if (route.startsWith('/quests')) return 1;
    if (route.startsWith('/leaderboard')) return 2;
    if (route.startsWith('/admin')) return 3;
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) return;

        // Check 1: Internal Navigator (e.g., deep links within a tab)
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
          return;
        }

        // Check 2: Custom Tab History
        if (_tabHistory.length > 1) {
          setState(() {
            _tabHistory.removeLast();
          });
          context.go(_tabHistory.last);
          return;
        }

        // Check 3: Root Tab -> Exit Safeguard
        _handleFinalBackPress();
      },
      child: Scaffold(
        body: widget.child,
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
              final bool isActive =
                  currentIndex == _getOriginalIndex(item.route);

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onBottomNavTapped(item.route),
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
