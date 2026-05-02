import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/core/errors/app_exception.dart';
import 'package:bitwise_academy/core/errors/result.dart';

/// Extension to provide a global timeout and logging to any Future.
extension FirebaseFutureExtension<T> on Future<T> {
  /// Adds a timeout and automatic logging if the operation hangs.
  Future<T> withGlobalTimeout({
    Duration duration = const Duration(seconds: 10),
    String? taskName,
  }) {
    return timeout(
      duration,
      onTimeout: () {
        final message =
            '⏰ [TIMEOUT] ${taskName ?? "Firebase operation"} exceeded ${duration.inSeconds}s';
        AppLogger.instance.e(message);
        throw TimeoutException(message);
      },
    );
  }
}

/// A mixin to provide guarded execution logic to Repositories.
mixin FirebaseGuardedExecution {
  /// Wraps a fallible Firebase call with timeouts, logging, and Result mapping.
  Future<Result<T>> guardedTask<T>(
    Future<T> Function() action, {
    String? taskName,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final result = await action().withGlobalTimeout(
        duration: timeout,
        taskName: taskName,
      );
      return Success<T>(result);
    } on TimeoutException catch (_) {
      return Failure<T>(
        FirestoreException(
          message: 'Connection timed out. Please check your signal.',
          code: 'timeout',
          stackTrace: StackTrace.current,
        ),
      );
    } on AppException catch (e) {
      return Failure<T>(e);
    } on SocketException catch (e, stackTrace) {
      // DNS failure, no route to host, network interface down, etc.
      AppLogger.instance.e(
        '$taskName failed (SocketException): ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
      return Failure<T>(
        FirestoreException(
          message: 'Network connection failed. Please check your internet.',
          code: 'network-unavailable',
          stackTrace: stackTrace,
        ),
      );
    } on FirebaseException catch (e, stackTrace) {
      // Firebase Auth's own wrapper around network-layer failures.
      if (e.code == 'network-request-failed') {
        AppLogger.instance.e(
          '$taskName failed (Firebase network): ${e.message}',
          error: e,
          stackTrace: stackTrace,
        );
        return Failure<T>(
          FirestoreException(
            message: 'Network connection failed. Please check your internet.',
            code: 'network-unavailable',
            stackTrace: stackTrace,
          ),
        );
      }
      // All other FirebaseExceptions fall through to the generic handler.
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'Unexpected error in $taskName: ${e.toString()}',
        error: e,
        stackTrace: stackTrace,
      );
      return Failure<T>(
        FirestoreException(
          message: e.toString(),
          code: 'unknown',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Wraps a Firebase Stream with automatic logging and Result mapping.
  Stream<Result<T>> guardedStream<T>(
    Stream<T> Function() streamAction, {
    required String taskName,
  }) {
    try {
      return streamAction().map((data) => Success<T>(data)).handleError((
        Object e,
        StackTrace stackTrace,
      ) {
        if (e is FirebaseException) {
          AppLogger.instance.e(
            '$taskName failed (Firebase): ${e.message}',
            error: e,
          );
          return Failure<T>(
            FirestoreException(
              message: e.message ?? 'Stream operation failed',
              code: e.code,
              stackTrace: stackTrace,
            ),
          );
        }
        AppLogger.instance.e(
          '$taskName failed (Unknown): ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        );
        return Failure<T>(
          FirestoreException(
            message: e.toString(),
            code: 'unknown',
            stackTrace: stackTrace,
          ),
        );
      });
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'Error setting up stream $taskName: ${e.toString()}',
        error: e,
        stackTrace: stackTrace,
      );
      return Stream.value(
        Failure<T>(
          FirestoreException(
            message: e.toString(),
            code: 'setup_error',
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }
}
