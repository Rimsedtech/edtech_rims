import 'package:flutter/material.dart';
import 'package:bitwise_academy/core/services/feature_flag_service.dart';

/// A widget that toggles its content based on a feature flag.
///
/// If the [flagName] is enabled in [FeatureFlagService], it renders the [onEnabled] widget.
/// Otherwise, it renders the [onDisabled] widget.
class FeatureToggle extends StatelessWidget {
  /// The unique name of the feature flag to check.
  final String flagName;

  /// The widget to display when the feature is enabled.
  final Widget onEnabled;

  /// The widget to display when the feature is disabled (defaults to an empty SizedBox).
  final Widget onDisabled;

  const FeatureToggle({
    super.key,
    required this.flagName,
    required this.onEnabled,
    this.onDisabled = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = FeatureFlagService().isEnabled(flagName);

    return isEnabled ? onEnabled : onDisabled;
  }
}
