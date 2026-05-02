/// Design system spacing tokens.
///
/// All spacing values are multiples of the 4px base unit.
/// NEVER hardcode raw pixel values in widgets — use [AppSpacing.*].
abstract final class AppSpacing {
  /// 4px — micro gaps, icon padding
  static const double xs = 4.0;

  /// 8px — tight element spacing
  static const double sm = 8.0;

  /// 12px — compact spacing
  static const double md12 = 12.0;

  /// 16px — standard content padding
  static const double md = 16.0;

  /// 20px — comfortable spacing
  static const double lg20 = 20.0;

  /// 24px — section gaps, card padding
  static const double lg = 24.0;

  /// 32px — large section separation
  static const double xl = 32.0;

  /// 48px — major layout divisions
  static const double xxl = 48.0;

  /// 64px — hero section spacing
  static const double xxxl = 64.0;

  // ── Common padding combinations ──

  /// Standard page-level horizontal padding (24px)
  static const double pageHorizontal = lg;

  /// Top bar height (64px)
  static const double appBarHeight = 64.0;

  /// Bottom nav height (80px)
  static const double bottomNavHeight = 80.0;

  // ── Border widths (pixel-art scale) ──

  /// Standard structural border
  static const double borderThin = 2.0;

  /// Heavy accent / active indicator
  static const double borderThick = 4.0;

  /// Section left-accent bar
  static const double borderAccent = 8.0;
}
