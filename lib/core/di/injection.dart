import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:bitwise_academy/core/services/auth_service.dart';
import 'package:bitwise_academy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bitwise_academy/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bitwise_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/auth/presentation/cubit/auth_form_cubit.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart';
import 'package:bitwise_academy/features/exam_library/data/repositories/attempt_repository.dart';
import 'package:bitwise_academy/features/exam_library/data/repositories/exam_repository.dart';
import 'package:bitwise_academy/features/exam_library/data/services/mock_test_service.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/attempt_repository.dart';
import 'package:bitwise_academy/features/exam_library/domain/repositories/exam_repository.dart';
import 'package:bitwise_academy/features/admin/presentation/cubit/admin_stats_cubit.dart';
import 'package:bitwise_academy/features/admin/presentation/cubit/admin_activity_cubit.dart';
import 'package:bitwise_academy/features/quest/presentation/bloc/quest_bloc.dart';
import 'package:bitwise_academy/features/quest/data/repositories/quest_repository.dart';
import 'package:bitwise_academy/features/quest/domain/repositories/quest_repository.dart';
import 'package:bitwise_academy/shared/domain/repositories/user_progress_repository.dart';
import 'package:bitwise_academy/shared/domain/repositories/user_repository.dart';
import 'package:bitwise_academy/shared/services/user_progress_repository.dart';
import 'package:bitwise_academy/shared/services/user_repository.dart';
import 'package:bitwise_academy/features/store/data/repositories/store_repository.dart';
import 'package:bitwise_academy/features/store/presentation/cubit/store_cubit.dart';
import 'package:bitwise_academy/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:bitwise_academy/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:bitwise_academy/features/jobs/data/repositories/job_repository.dart';
import 'package:bitwise_academy/features/jobs/presentation/cubit/jobs_cubit.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/session_recovery_bloc.dart';

/// Global [GetIt] service locator instance.
final GetIt getIt = GetIt.instance;

/// Registers all dependencies with [GetIt].
///
/// Registration order:
/// 1. External services (Firebase, Google Sign-In)
/// 2. Data sources
/// 3. Repositories
/// 4. BLoCs / Cubits
Future<void> configureDependencies() async {
  // ── 1. External Services ──
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  getIt.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

  // ── 2. Data Sources ──
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(
      firebaseAuth: getIt<FirebaseAuth>(),
      googleSignIn: getIt<GoogleSignIn>(),
    ),
  );

  // ── 3. Repositories ──
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authDataSource: getIt<AuthRemoteDataSource>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerLazySingleton<MockTestService>(
    () => MockTestService(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<ExamRepository>(
    () => ExamRepositoryImpl(
      firestore: getIt<FirebaseFirestore>(),
      storage: getIt<FirebaseStorage>(),
    ),
  );
  getIt.registerLazySingleton<AttemptRepository>(
    () => AttemptRepositoryImpl(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<QuestRepository>(
    () => QuestRepositoryImpl(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<UserProgressRepository>(
    () => UserProgressRepositoryImpl(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<StoreRepository>(
    () => StoreRepository(
      firestore: getIt<FirebaseFirestore>(),
      storage: getIt<FirebaseStorage>(),
    ),
  );
  getIt.registerLazySingleton<JobRepository>(
    () => JobRepository(firestore: getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<AuthService>(
    () => AuthService(authRepository: getIt<AuthRepository>()),
  );

  // ── 4. BLoCs / Cubits ──
  //
  // AuthBloc is a SINGLETON: the same instance is shared by AppRoot,
  // AuthFormCubit, and any other consumer. This is required so that:
  //   • The authStateChanges stream subscription is set up exactly once.
  //   • _isFormOperationInProgress flag is consistent across all callers.
  //   • SessionRecoveryBloc receives CheckRecoveryRequested from the correct
  //     bloc instance (not a different factory-created one).
  //
  // ⚠️ Singleton risks mitigated:
  //   1. AuthFormCubit.close() now sends AuthFormOperationCompleted to reset
  //      _isFormOperationInProgress if the cubit is disposed mid-operation.
  //   2. AuthBloc.close() is NOT called in RimsApp.dispose() — GetIt owns
  //      the singleton lifecycle for the entire app session.
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerFactory<AuthFormCubit>(
    () => AuthFormCubit(
      authRepository: getIt<AuthRepository>(),
      authBloc: getIt<AuthBloc>(),
    ),
  );
  getIt.registerFactory<AttemptBloc>(
    () => AttemptBloc(
      attemptRepository: getIt<AttemptRepository>(),
      examRepository: getIt<ExamRepository>(),
      mockTestService: getIt<MockTestService>(),
      userProgressRepository: getIt<UserProgressRepository>(),
    ),
  );
  getIt.registerFactory<AdminStatsCubit>(
    () => AdminStatsCubit(
      examRepository: getIt<ExamRepository>(),
      userRepository: getIt<UserRepository>(),
      attemptRepository: getIt<AttemptRepository>(),
    ),
  );
  getIt.registerFactory<AdminActivityCubit>(
    () => AdminActivityCubit(
      attemptRepository: getIt<AttemptRepository>(),
      examRepository: getIt<ExamRepository>(),
      userRepository: getIt<UserRepository>(),
    ),
  );
  getIt.registerFactory<QuestBloc>(
    () => QuestBloc(
      questRepository: getIt<QuestRepository>(),
      userProgressRepository: getIt<UserProgressRepository>(),
    ),
  );
  getIt.registerFactory<StoreCubit>(
    () => StoreCubit(
      storeRepository: getIt<StoreRepository>(),
      userProgressRepository: getIt<UserProgressRepository>(),
      userRepository: getIt<UserRepository>(),
    ),
  );
  getIt.registerFactory<DashboardCubit>(
    () => DashboardCubit(
      userRepository: getIt<UserRepository>(),
      attemptRepository: getIt<AttemptRepository>(),
    ),
  );
  getIt.registerFactory<LeaderboardBloc>(
    () => LeaderboardBloc(userRepository: getIt<UserRepository>()),
  );
  getIt.registerFactory<SessionRecoveryBloc>(
    () => SessionRecoveryBloc(
      attemptRepository: getIt<AttemptRepository>(),
      examRepository: getIt<ExamRepository>(),
      userProgressRepository: getIt<UserProgressRepository>(),
    ),
  );
  // registerFactory: each Dashboard instance needs its own stream subscription
  // that gets cancelled when the cubit is closed via JobsCubit.close().
  getIt.registerFactory<JobsCubit>(
    () => JobsCubit(repo: getIt<JobRepository>()),
  );
}
