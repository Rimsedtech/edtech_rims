import 'package:equatable/equatable.dart';
import 'package:bitwise_academy/features/jobs/data/models/job_advertisement.dart';

abstract class JobsState extends Equatable {
  const JobsState();

  @override
  List<Object?> get props => [];
}

class JobsInitial extends JobsState {
  const JobsInitial();
}

class JobsLoading extends JobsState {
  const JobsLoading();
}

class JobsLoaded extends JobsState {
  final List<JobAdvertisement> jobs;
  const JobsLoaded(this.jobs);

  @override
  List<Object?> get props => [jobs];
}

class JobsError extends JobsState {
  final String message;
  const JobsError(this.message);

  @override
  List<Object?> get props => [message];
}
