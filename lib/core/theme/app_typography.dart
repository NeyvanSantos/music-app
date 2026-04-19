import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/theme/app_colors.dart';

/// Estilos tipográficos do aplicativo.
///
/// Usa a família Manrope via GoogleFonts como fonte principal.
abstract class AppTypography {
  AppTypography._();

  // ─── Display ─────────────────────────────────────────────
  static final TextStyle displayLarge = GoogleFonts.manrope(
    fontSize: 56,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
    letterSpacing: -3,
    height: 1.1,
  );

  static final TextStyle displayMedium = GoogleFonts.manrope(
    fontSize: 42,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: -2,
    height: 1.15,
  );

  static final TextStyle displaySmall = GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: -1.5,
    height: 1.2,
  );

  // ─── Headlines ───────────────────────────────────────────
  static final TextStyle headlineLarge = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: -0.5,
  );

  static final TextStyle headlineMedium = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: -0.3,
  );

  static final TextStyle headlineSmall = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  // ─── Titles ──────────────────────────────────────────────
  static final TextStyle titleLarge = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: 0.2,
  );

  static final TextStyle titleMedium = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static final TextStyle titleSmall = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
  );

  // ─── Body ────────────────────────────────────────────────
  static final TextStyle bodyLarge = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static final TextStyle bodyMedium = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.5,
  );

  static final TextStyle bodySmall = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  // ─── Labels ──────────────────────────────────────────────
  static final TextStyle labelLarge = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 1.5,
  );

  static final TextStyle labelMedium = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 2,
  );

  static final TextStyle labelSmall = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceMuted,
    letterSpacing: 2.5,
  );
}

