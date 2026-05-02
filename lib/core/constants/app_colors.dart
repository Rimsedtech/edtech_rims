import 'dart:ui';

/// Neo-Arcade Editorial color palette.
///
/// All colors derived from the DESIGN.md specification.
/// NEVER use [Colors.*] from Material — always use [AppColors.*].
abstract final class AppColors {
  // ── Primary ──
  static const Color primary = Color(0xFF242E48);
  static const Color primaryContainer = Color(0xFF3A4460);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFA7B1D3);
  static const Color primaryFixed = Color(0xFFDAE2FF);
  static const Color primaryFixedDim = Color(0xFFBCC6E8);

  // ── Secondary ──
  static const Color secondary = Color(0xFF3E6A00);
  static const Color secondaryContainer = Color(0xFFB2F26A);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF416E00);
  static const Color secondaryFixed = Color(0xFFB5F56C);
  static const Color secondaryFixedDim = Color(0xFF9AD853);

  // ── Tertiary ──
  static const Color tertiary = Color(0xFF64000F);
  static const Color tertiaryContainer = Color(0xFF8B0C1C);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFF9491);
  static const Color tertiaryFixed = Color(0xFFFFDAD8);
  static const Color tertiaryFixedDim = Color(0xFFFFB3B0);

  // ── Surface hierarchy ──
  static const Color surface = Color(0xFFFBF8FB);
  static const Color surfaceBright = Color(0xFFFBF8FB);
  static const Color surfaceDim = Color(0xFFDCD9DC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F3F5);
  static const Color surfaceContainer = Color(0xFFF0EDF0);
  static const Color surfaceContainerHigh = Color(0xFFEAE7EA);
  static const Color surfaceContainerHighest = Color(0xFFE4E2E4);
  static const Color surfaceVariant = Color(0xFFE4E2E4);
  static const Color surfaceTint = Color(0xFF545E7B);

  // ── On-Surface ──
  static const Color onSurface = Color(0xFF1B1B1D);
  static const Color onSurfaceVariant = Color(0xFF45464D);
  static const Color onBackground = Color(0xFF1B1B1D);
  static const Color background = Color(0xFFFBF8FB);

  // ── Outline ──
  static const Color outline = Color(0xFF76777E);
  static const Color outlineVariant = Color(0xFFC6C6CE);

  // ── Error ──
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Inverse ──
  static const Color inverseSurface = Color(0xFF303032);
  static const Color inverseOnSurface = Color(0xFFF3F0F2);
  static const Color inversePrimary = Color(0xFFBCC6E8);

  // ── Shadows (tinted, per design spec) ──
  /// Hard 8-bit shadow: [onSurface] at 6% opacity
  static const Color shadowTinted = Color(0x0F1B1B1D);

  /// Ghost border: [outlineVariant] at 15% opacity
  static const Color ghostBorder = Color(0x26C6C6CE);
}
