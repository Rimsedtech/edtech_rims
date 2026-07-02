import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/core/router/app_router.dart';
import 'package:bitwise_academy/core/theme/app_theme.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart';
import 'package:bitwise_academy/features/quest/presentation/bloc/quest_bloc.dart';
import 'package:bitwise_academy/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/session_recovery_bloc.dart';
import 'package:bitwise_academy/core/widgets/quest_celebration_overlay.dart';

/// Root application widget.
class RimsApp extends StatefulWidget {
  const RimsApp({super.key});

  @override
  State<RimsApp> createState() => _RimsAppState();
}

class _RimsAppState extends State<RimsApp> {
  late final AuthBloc _authBloc;
  late final SessionRecoveryBloc _sessionRecoveryBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // AuthBloc is a singleton — do NOT dispatch AuthCheckRequested.
    // The bloc starts in AuthLoading and resolves automatically when the
    // Firebase authStateChanges stream fires with the persisted auth state.
    _authBloc = getIt<AuthBloc>();
    _sessionRecoveryBloc = getIt<SessionRecoveryBloc>();
    _router = buildRouter(_authBloc, _sessionRecoveryBloc);
  }

  @override
  void dispose() {
    _router.dispose();
    _sessionRecoveryBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<SessionRecoveryBloc>.value(value: _sessionRecoveryBloc),
        BlocProvider<AttemptBloc>(create: (_) => getIt<AttemptBloc>()),
        BlocProvider<QuestBloc>(create: (_) => getIt<QuestBloc>()),
        BlocProvider<LeaderboardBloc>(create: (_) => getIt<LeaderboardBloc>()),
      ],
      // Drive the quest stream lifecycle from auth state.
      // The stream starts only when the user is authenticated,
      // and is cancelled on logout to prevent PERMISSION_DENIED errors.
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          final questBloc = context.read<QuestBloc>();
          final recoveryBloc = context.read<SessionRecoveryBloc>();
          
          if (authState is AuthAuthenticated) {
            // Only start the quest stream subscription if not already active.
            // AuthAuthenticated fires on EVERY user update (e.g. XP/coin award
            // after an exam). Re-dispatching LoadActiveQuestsRequested each time
            // cancels and re-creates the Firestore stream unnecessarily.
            final questState = questBloc.state;
            if (questState is! QuestLoadSuccess && questState is! QuestLoadInProgress) {
              questBloc.add(const LoadActiveQuestsRequested());
            }
            // Only run the recovery check on INITIAL login — not on every
            // AuthAuthenticated emission (e.g. AuthUserUpdated from XP/coins
            // being awarded after an exam). Re-triggering CheckRecoveryRequested
            // causes the router to cycle through RecoveryChecking → /splash →
            // RecoveryNone → / which boots the user off the results page.
            if (recoveryBloc.state is RecoveryInitial) {
              recoveryBloc.add(CheckRecoveryRequested(authState.user.uid));
            }
          } else if (authState is AuthUnauthenticated ||
              authState is AuthInitial) {
            questBloc.add(const StopQuestListening());
            recoveryBloc.add(const ResetRecoveryState());
          }
        },
        child: BlocListener<QuestBloc, QuestState>(
          listenWhen: (previous, current) => current is QuestXpAwardSuccess,
          listener: (context, state) {
            if (state is QuestXpAwardSuccess) {
              _showCelebration(context, state);
              context.read<QuestBloc>().add(const AcknowledgeQuestXpAward());
            }
          },
          child: MaterialApp.router(
            title: 'RIMS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }

  void _showCelebration(BuildContext context, QuestXpAwardSuccess state) {
    // We use showGeneralDialog to have full control over the overlay
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Quest Celebration',
      barrierColor: Colors.transparent, // Handled by overlay itself
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return QuestCelebrationOverlay(
          questTitle: state.quest.title,
          xpAwarded: state.xpAwarded,
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
