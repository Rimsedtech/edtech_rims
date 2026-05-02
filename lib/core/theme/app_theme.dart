import 'package:flutter/material.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';

/// Constructs the Neo-Arcade Editorial [ThemeData].
///
/// Enforces: 0px border radius everywhere, custom color scheme,
/// pixel-art typography, chunky component styles.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.surface,

    // ── Color Scheme ──
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryContainer,
      onPrimary: AppColors.onPrimary,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondary: AppColors.onSecondary,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiary: AppColors.onTertiary,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      error: AppColors.error,
      errorContainer: AppColors.errorContainer,
      onError: AppColors.onError,
      onErrorContainer: AppColors.onErrorContainer,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
      surfaceTint: AppColors.surfaceTint,
    ),

    // ── Typography ──
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLg,
      headlineMedium: AppTypography.headlineMd,
      headlineSmall: AppTypography.headlineSm,
      bodyLarge: AppTypography.bodyLg,
      bodyMedium: AppTypography.bodyMd,
      labelLarge: AppTypography.labelLg,
      labelMedium: AppTypography.labelMd,
      labelSmall: AppTypography.labelSm,
    ),

    // ── Global: 0px border radius ──
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
    ),

    // ── AppBar ──
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.primaryContainer,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.headlineSm.copyWith(
        color: AppColors.primaryContainer,
      ),
      shape: const Border(
        bottom: BorderSide(color: AppColors.primaryContainer, width: 4),
      ),
    ),

    // ── Elevated Button ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppTypography.headlineXs,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),

    // ── Outlined Button ──
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppTypography.headlineXs,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),

    // ── Text Button ──
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondary,
        textStyle: AppTypography.labelLg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),

    // ── Input Fields ──
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.secondary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: AppTypography.bodyLg.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
      hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.outline),
      errorStyle: AppTypography.labelMd.copyWith(color: AppColors.error),
    ),

    // ── Bottom Navigation Bar ──
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.primaryContainer,
      selectedItemColor: AppColors.secondaryFixed,
      unselectedItemColor: AppColors.surfaceContainerHighest,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: AppTypography.labelLg,
      unselectedLabelStyle: AppTypography.labelLg,
    ),

    // ── Chip ──
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceContainerHigh,
      selectedColor: AppColors.secondaryContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      labelStyle: AppTypography.labelMd,
    ),

    // ── Dialog ──
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),

    // ── Divider ──
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceContainerHighest,
      thickness: 2,
      space: 0,
    ),

    // ── Snackbar ──
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.inverseSurface,
      contentTextStyle: AppTypography.bodyLg.copyWith(
        color: AppColors.inverseOnSurface,
      ),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Tab Bar ──
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.secondary,
      unselectedLabelColor: AppColors.onSurfaceVariant,
      labelStyle: AppTypography.labelLg,
      unselectedLabelStyle: AppTypography.labelLg,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: AppColors.secondary, width: 4),
      ),
    ),
  );
}
