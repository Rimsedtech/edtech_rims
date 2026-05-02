import 'package:flutter/foundation.dart';

/// A singleton service to manage feature flags within the application.
///
/// This service acts as a safety net for new UI features, allowing them to be
/// toggled on/off without a full app deployment. It is designed to eventually
/// connect to Firebase Remote Config.
class FeatureFlagService {
  // Singleton instance
  static final FeatureFlagService _instance = FeatureFlagService._internal();

  factory FeatureFlagService() => _instance;

  FeatureFlagService._internal();

  /// Local map of feature flags.
  ///
  /// In the future, this will be synchronized with Firebase Remote Config.
  final Map<String, bool> _flags = {
    'show_pixel_storefront': false,
    'enable_pixel_widgets': false,
    'show_experimental_ui': false,
  };

  /// Checks if a specific feature flag is enabled.
  ///
  /// Returns [true] if the flag exists and is set to true, otherwise [false].
  bool isEnabled(String flagName) {
    final isEnabled = _flags[flagName] ?? false;

    // Log feature flag checks in debug mode
    if (kDebugMode) {
      debugPrint(
        'FeatureFlag: $flagName is ${isEnabled ? "ENABLED" : "DISABLED"}',
      );
    }

    return isEnabled;
  }

  /// Manually set a flag (useful for testing or local overrides).
  void setFlag(String flagName, bool value) {
    _flags[flagName] = value;
  }
}
