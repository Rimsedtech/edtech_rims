import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/auth/presentation/cubit/auth_form_cubit.dart';
import 'package:bitwise_academy/features/auth/presentation/pages/login_page.dart';
import 'package:bitwise_academy/features/auth/presentation/pages/register_page.dart';
import 'package:bitwise_academy/features/auth/presentation/pages/recovery_page.dart';
import 'package:bitwise_academy/features/dashboard/presentation/pages/user_dashboard_page.dart';

import 'package:bitwise_academy/features/quest/presentation/pages/quest_page.dart';
import 'package:bitwise_academy/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:bitwise_academy/features/admin/presentation/pages/create_exam_page.dart';
import 'package:bitwise_academy/features/admin/presentation/pages/exam_management_page.dart';
import 'package:bitwise_academy/features/admin/presentation/pages/create_questions_page.dart';
import 'package:bitwise_academy/features/leaderboard/presentation/pages/leaderboard_page.dart';
import 'package:bitwise_academy/features/exam_library/presentation/pages/exam_taking_page.dart';
import 'package:bitwise_academy/features/exam_library/presentation/pages/exam_results_page.dart';
import 'package:bitwise_academy/core/widgets/shell_scaffold.dart';
import 'package:bitwise_academy/core/widgets/feature_toggle.dart';

import 'package:bitwise_academy/features/admin/presentation/pages/admin_upload_skin_page.dart';
import 'package:bitwise_academy/features/store/presentation/pages/avatar_store_page.dart';
import 'package:bitwise_academy/features/store/presentation/cubit/store_cubit.dart';
import 'package:bitwise_academy/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/core/constants/app_constants.dart';

/// Route path constants to avoid hardcoded strings.
abstract final class RoutePaths {
  static const String login = '/login';
  static const String register = '/register';
  static const String recovery = '/recovery';
  static const String dashboard = '/';

  static const String examTaking = '/exams/:examId/take';
  static const String examResults = '/exams/:examId/results';
  static const String quests = '/quests';
  static const String store = '/store';
  static const String leaderboard = '/leaderboard';
  static const String adminDashboard = '/admin';
  static const String adminCreateExam = '/admin/create-exam';
  static const String adminManageExams = '/admin/manage-exams';
  static const String adminUploadSkin = '/admin/upload-skin';
  static const String adminCreateQuestions = '/admin/exams/:examId/questions';

  /// Avatar / Profile selection shown once after registration.
  /// Bypassed automatically when [AppConstants.isAvatarSystemEnabled] is [false].
  /// To restore the full onboarding flow, flip the flag to [true] and replace
  /// [_AvatarSelectionPlaceholder] with your real [AvatarSelectionPage].
  static const String avatarSelection = '/avatar-selection';
}

/// Converts a [Stream] into a [Listenable] for GoRouter's
/// `refreshListenable` so that route redirects re-evaluate
/// whenever the auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Builds the [GoRouter] configuration with auth-based redirects.
///
/// Auth flow:
/// - Unauthenticated users are redirected to [/login].
/// - Authenticated students see the shell with bottom nav.
/// - Admin routes require `role == 'admin'` (enforced server-side by
///   Firestore rules; client redirect is a UX convenience).
GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: RoutePaths.login,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState authState = context.read<AuthBloc>().state;
      final bool isOnAuthPage =
          state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register ||
          state.matchedLocation == RoutePaths.recovery;

      // If authenticated and on an auth page, redirect to dashboard
      if (authState is AuthAuthenticated && isOnAuthPage) {
        return RoutePaths.dashboard;
      }

      // If not authenticated and NOT on an auth page, redirect to login
      if (authState is! AuthAuthenticated && !isOnAuthPage) {
        return RoutePaths.login;
      }

      // If on admin page but not admin, redirect to dashboard
      if (authState is AuthAuthenticated &&
          state.matchedLocation.startsWith('/admin') &&
          !authState.user.isAdmin) {
        return RoutePaths.dashboard;
      }

      // ── Avatar Selection feature gate ──────────────────────────────────────
      // When the flag is off, redirect any attempt to reach the avatar screen
      // straight to the dashboard.  Flip AppConstants.isAvatarSystemEnabled to
      // true (and wire up the real AvatarSelectionPage) to restore the flow.
      if (!AppConstants.isAvatarSystemEnabled &&
          state.matchedLocation == RoutePaths.avatarSelection) {
        return RoutePaths.dashboard;
      }

      return null; // No redirect needed
    },
    routes: <RouteBase>[
      // ── Auth routes (no shell) ──
      GoRoute(
        path: RoutePaths.login,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) => BlocProvider(
          create: (_) => getIt<AuthFormCubit>(),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: 'register',
        builder: (BuildContext context, GoRouterState state) => BlocProvider(
          create: (_) => getIt<AuthFormCubit>(),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.recovery,
        name: 'recovery',
        builder: (BuildContext context, GoRouterState state) => BlocProvider(
          create: (_) => getIt<AuthFormCubit>(),
          child: const RecoveryPage(),
        ),
      ),

      // ── Avatar Selection (gated by AppConstants.isAvatarSystemEnabled) ──────
      // The redirect above prevents this route from being reached while the flag
      // is false.  When you're ready to go live:
      //   1. Set AppConstants.isAvatarSystemEnabled = true
      //   2. Import your AvatarSelectionPage and replace _AvatarSelectionPlaceholder
      GoRoute(
        path: RoutePaths.avatarSelection,
        name: 'avatarSelection',
        builder: (BuildContext context, GoRouterState state) =>
            const _AvatarSelectionPlaceholder(),
      ),

      GoRoute(
        path: RoutePaths.examTaking,
        name: 'examTaking',
        builder: (BuildContext context, GoRouterState state) =>
            ExamTakingPage(examId: state.pathParameters['examId'] ?? ''),
      ),
      GoRoute(
        path: RoutePaths.examResults,
        name: 'examResults',
        builder: (BuildContext context, GoRouterState state) =>
            ExamResultsPage(examId: state.pathParameters['examId'] ?? ''),
      ),

      // ── Main app shell (with bottom nav) ──
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            ShellScaffold(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: RoutePaths.dashboard,
            name: 'dashboard',
            builder: (BuildContext context, GoRouterState state) {
              final authState = context.read<AuthBloc>().state;
              final userId = authState is AuthAuthenticated
                  ? authState.user.uid
                  : '';
              return BlocProvider(
                create: (_) => getIt<DashboardCubit>()..loadDashboard(userId),
                child: const UserDashboardPage(),
              );
            },
          ),

          GoRoute(
            path: RoutePaths.quests,
            name: 'quests',
            builder: (BuildContext context, GoRouterState state) =>
                const QuestPage(),
          ),
          GoRoute(
            path: RoutePaths.store,
            name: 'store',
            builder: (BuildContext context, GoRouterState state) =>
                FeatureToggle(
                  flagName: 'show_pixel_storefront',
                  onEnabled: const Scaffold(
                    body: Center(
                      child: Text(
                        'New Pixel UI Coming Soon',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  onDisabled: BlocProvider(
                    create: (_) => getIt<StoreCubit>()..loadSkins(),
                    child: const AvatarStorePage(),
                  ),
                ),
          ),
          GoRoute(
            path: RoutePaths.leaderboard,
            name: 'leaderboard',
            builder: (BuildContext context, GoRouterState state) =>
                const LeaderboardPage(),
          ),

          // ── Admin routes (inside shell) ──
          GoRoute(
            path: RoutePaths.adminDashboard,
            name: 'adminDashboard',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminDashboardPage(),
          ),
          GoRoute(
            path: RoutePaths.adminCreateExam,
            name: 'adminCreateExam',
            builder: (BuildContext context, GoRouterState state) =>
                const CreateExamPage(),
          ),
          GoRoute(
            path: RoutePaths.adminManageExams,
            name: 'adminManageExams',
            builder: (BuildContext context, GoRouterState state) =>
                const ExamManagementPage(),
          ),
          GoRoute(
            path: RoutePaths.adminUploadSkin,
            name: 'adminUploadSkin',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminUploadSkinPage(),
          ),
          GoRoute(
            path: RoutePaths.adminCreateQuestions,
            name: 'adminCreateQuestions',
            builder: (BuildContext context, GoRouterState state) =>
                CreateQuestionsPage(
                  examId: state.pathParameters['examId'] ?? '',
                ),
          ),
        ],
      ),
    ],
  );
}

// ── Stub ─────────────────────────────────────────────────────────────────────

/// Temporary placeholder rendered at [RoutePaths.avatarSelection].
/// The router redirect prevents this from ever being displayed while
/// [AppConstants.isAvatarSystemEnabled] is [false].
///
/// **To activate the real screen:**
/// ```dart
/// // 1. In app_constants.dart
/// static const bool isAvatarSystemEnabled = true;
///
/// // 2. In app_router.dart – avatarSelection GoRoute builder
/// builder: (context, state) => const AvatarSelectionPage(),
/// ```
class _AvatarSelectionPlaceholder extends StatelessWidget {
  const _AvatarSelectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Avatar Selection\n(Feature disabled — set isAvatarSystemEnabled = true)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
