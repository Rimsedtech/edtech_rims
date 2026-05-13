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
import 'package:bitwise_academy/features/admin/presentation/cubit/admin_stats_cubit.dart';
import 'package:bitwise_academy/features/quest/presentation/bloc/quest_bloc.dart';
import 'package:bitwise_academy/features/quest/data/repositories/quest_repository.dart';
import 'package:bitwise_academy/shared/services/user_progress_repository.dart';
import 'package:bitwise_academy/shared/services/user_repository.dart';
import 'package:bitwise_academy/features/store/data/repositories/store_repository.dart';
import 'package:bitwise_academy/features/store/presentation/cubit/store_cubit.dart';
import 'package:bitwise_academy/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:bitwise_academy/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';

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
    () => ExamRepository(
      firestore: getIt<FirebaseFirestore>(),
      storage: getIt<FirebaseStorage>(),
    ),
  );
  getIt.registerLazySingleton<AttemptRepository>(
    () => AttemptRepository(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<QuestRepository>(
    () => QuestRepository(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<UserProgressRepository>(
    () => UserProgressRepository(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<StoreRepository>(
    () => StoreRepository(
      firestore: getIt<FirebaseFirestore>(),
      storage: getIt<FirebaseStorage>(),
    ),
  );

  getIt.registerLazySingleton<AuthService>(
    () => AuthService(authRepository: getIt<AuthRepository>()),
  );

  // ── 4. BLoCs / Cubits ──
  getIt.registerFactory<AuthBloc>(
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
}
