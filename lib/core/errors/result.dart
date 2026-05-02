import 'package:bitwise_academy/core/errors/app_exception.dart';

/// A sealed Result type for handling fallible operations.
///
/// All repository and service methods that can fail MUST return
/// [Result<T>] instead of throwing exceptions. BLoCs/Cubits then
/// pattern-match on [Success] / [Failure] to emit the correct state.
///
/// ```dart
/// final Result<List<Exam>> result = await examRepo.fetchAll();
/// switch (result) {
///   case Success(:final data):
///     emit(ExamListLoaded(exams: data));
///   case Failure(:final exception):
///     emit(ExamListError(message: exception.message));
/// }
/// ```
sealed class Result<T> {
  const Result();
}

/// Represents a successful operation containing [data].
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed operation containing an [AppException].
final class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);

  @override
  String toString() => 'Failure(${exception.message})';
}
