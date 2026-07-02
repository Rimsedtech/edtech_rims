import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitwise_academy/features/jobs/data/models/job_advertisement.dart';
import 'package:bitwise_academy/features/jobs/data/repositories/job_repository.dart';
import 'package:bitwise_academy/features/jobs/presentation/cubit/jobs_state.dart';

/// Cubit that subscribes to the [JobRepository] stream and exposes
/// [JobsLoading], [JobsLoaded], and [JobsError] states to the UI.
///
/// Registered as a [registerFactory] in GetIt so that each Dashboard
/// instance gets its own stream subscription that is cancelled on dispose.
class JobsCubit extends Cubit<JobsState> {
  final JobRepository _repo;
  StreamSubscription<List<JobAdvertisement>>? _subscription;

  JobsCubit({required JobRepository repo})
      : _repo = repo,
        super(const JobsLoading()) {
    _subscribe();
  }

  void _subscribe() {
    emit(const JobsLoading());
    _subscription = _repo.watchActiveJobs().listen(
      (jobs) => emit(JobsLoaded(jobs)),
      onError: (Object e) => emit(JobsError(e.toString())),
    );
  }

  /// Allows the UI to trigger a manual re-subscription on error.
  void retry() {
    _subscription?.cancel();
    _subscribe();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
