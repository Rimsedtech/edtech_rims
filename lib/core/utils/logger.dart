import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Singleton logger instance for the app.
///
/// Usage:
/// ```dart
/// AppLogger.instance.d('Debug message');
/// AppLogger.instance.w('Warning message');
/// AppLogger.instance.e('Error message', error: exception, stackTrace: st);
/// ```
///
/// NEVER log sensitive data (passwords, tokens, full emails).
abstract final class AppLogger {
  static final Logger instance = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kReleaseMode ? Level.warning : Level.debug,
  );
}
