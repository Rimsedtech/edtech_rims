/// Form validation helpers.
///
/// Used by auth forms, exam creation, and any user-input flow.
/// Returns `null` if valid, error message string if invalid.
abstract final class Validators {
  /// Validates an email address format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'EMAIL_REQUIRED';
    }
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'INVALID_EMAIL_FORMAT';
    }
    return null;
  }

  /// Validates password meets minimum security requirements.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'PASSWORD_REQUIRED';
    }
    if (value.length < 8) {
      return 'PASSWORD_TOO_SHORT';
    }
    return null;
  }

  /// Validates a required text field is not empty.
  static String? required(String? value, {String fieldName = 'FIELD'}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName}_REQUIRED';
    }
    return null;
  }

  /// Validates a number is within a range.
  static String? numberInRange(
    String? value, {
    required int min,
    required int max,
    String fieldName = 'VALUE',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName}_REQUIRED';
    }
    final int? number = int.tryParse(value.trim());
    if (number == null) {
      return '${fieldName}_MUST_BE_NUMBER';
    }
    if (number < min || number > max) {
      return '${fieldName}_OUT_OF_RANGE ($min-$max)';
    }
    return null;
  }
}
