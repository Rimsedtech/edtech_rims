import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Neo-Arcade Editorial typography scale.
///
/// Three font families:
/// - **Press Start 2P** — Display & Headlines (hero moments)
/// - **VT323** — Titles, Body, Labels (workhorse)
/// - **Space Grotesk** — Administrative micro-labels, data tables
abstract final class AppTypography {
  // ── Press Start 2P — Display & Headlines ──

  /// 3.5rem / 56px — Hero banners, splash screens
  static TextStyle get displayLg => GoogleFonts.pressStart2p(
    fontSize: 56,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.5,
    height: 1.3,
  );

  /// 1.75rem / 28px — Section headers, level titles
  static TextStyle get headlineMd => GoogleFonts.pressStart2p(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    height: 1.4,
  );

  /// 0.875rem / 14px — Card titles, sub-headings
  static TextStyle get headlineSm => GoogleFonts.pressStart2p(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// 0.625rem / 10px — Tiny arcade labels, badges
  static TextStyle get headlineXs => GoogleFonts.pressStart2p(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  // ── VT323 — Body & Labels ──

  /// 1.5rem / 24px — Large body, stat values
  static TextStyle get bodyXl =>
      GoogleFonts.vt323(fontSize: 24, fontWeight: FontWeight.w400, height: 1.3);

  /// 1.125rem / 18px — Primary body text, descriptions
  static TextStyle get bodyLg =>
      GoogleFonts.vt323(fontSize: 18, fontWeight: FontWeight.w400, height: 1.4);

  /// 1rem / 16px — Standard content
  static TextStyle get bodyMd =>
      GoogleFonts.vt323(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);

  /// 1.25rem / 20px — Button labels, nav items
  static TextStyle get labelLg => GoogleFonts.vt323(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 2.0,
    height: 1.3,
  );

  /// 0.875rem / 14px — Metadata, timestamps
  static TextStyle get labelMd =>
      GoogleFonts.vt323(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4);

  // ── Space Grotesk — Administrative ──

  /// 0.75rem / 12px — Data table headers, admin text
  static TextStyle get labelSm => GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// 0.875rem / 14px — Admin body text
  static TextStyle get adminBody => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// 1rem / 16px — Admin section titles
  static TextStyle get adminTitle => GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );
}
