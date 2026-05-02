class AppConstants {
  static const List<String> allowedDomains = [
    'bitwiseacademy.com',
    'gmail.com',
  ];

  static const int recoveryKeyLength = 12;

  // ── Feature Flags ──────────────────────────────────────────────────────────

  /// Controls the Avatar / Profile Selection onboarding screen.
  ///
  /// Set to [true] to re-enable the post-registration avatar picker so that
  /// new users are routed to [RoutePaths.avatarSelection] after sign-up.
  /// When [false] (default), users land directly on the Home Screen and every
  /// new Firestore profile automatically receives [defaultAvatarId].
  static const bool isAvatarSystemEnabled = false;

  // ── Defaults ───────────────────────────────────────────────────────────────

  /// Avatar identifier written to every new user's Firestore document while
  /// [isAvatarSystemEnabled] is [false].
  ///
  /// Update this to a real asset path or Firebase Storage URL once the avatar
  /// system is live and you have a proper default asset in place.
  static const String defaultAvatarId = 'default_avatar';
}
