import 'package:flutter/material.dart';

/// Paleta de cores do design system Nocturne.
///
/// Atualizado para Amarelo Neon como cor principal.
abstract class AppColors {
  AppColors._();

  // ─── Primary (Amarelo Neon) ──────────────────────────────
  static const Color primary = Color(0xFFFAFF00); // Neon Yellow
  static const Color primaryDim = Color(0xFFD4D900);
  static const Color primaryFixed = Color(0xFFFBFF3D);
  static const Color primaryContainer = Color(0xFFFAFF00);
  static const Color onPrimary = Color(0xFF000000); // Black for high contrast
  static const Color onPrimaryContainer = Color(0xFF000000);

  // ─── Secondary (Verde Neon) ──────────────────────────────
  static const Color secondary = Color(0xFF6BFF8F);
  static const Color secondaryDim = Color(0xFF5BF083);
  static const Color secondaryContainer = Color(0xFF006E2F);
  static const Color onSecondary = Color(0xFF005F28);
  static const Color onSecondaryContainer = Color(0xFFE4FFE2);

  // ─── Tertiary (Roxo/Lavanda) ─────────────────────────────
  static const Color tertiary = Color(0xFFE1C3FF);
  static const Color tertiaryDim = Color(0xFFC8A5ED);

  // ─── Surface / Background ────────────────────────────────
  static const Color background = Color(0xFF0E0E0E);
  static const Color surface = Color(0xFF0E0E0E);
  static const Color surfaceDim = Color(0xFF0E0E0E);
  static const Color surfaceContainerLowest = Color(0xFF000000);
  static const Color surfaceContainerLow = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF1A1A1A);
  static const Color surfaceContainerHigh = Color(0xFF20201F);
  static const Color surfaceContainerHighest = Color(0xFF262626);
  static const Color surfaceBright = Color(0xFF2C2C2C);
  static const Color surfaceVariant = Color(0xFF262626);

  // ─── On Surface ──────────────────────────────────────────
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFADAAAa);
  static const Color onBackground = Color(0xFFFFFFFF);

  // ─── Outline ─────────────────────────────────────────────
  static const Color outline = Color(0xFF767575);
  static const Color outlineVariant = Color(0xFF484847);

  // ─── Error ───────────────────────────────────────────────
  static const Color error = Color(0xFFFF6E84);
  static const Color errorDim = Color(0xFFD73357);
  static const Color errorContainer = Color(0xFFA70138);
  static const Color onError = Color(0xFF490013);

  // ─── Inverse ─────────────────────────────────────────────
  static const Color inverseSurface = Color(0xFFFCF9F8);
  static const Color inverseOnSurface = Color(0xFF565555);
  static const Color inversePrimary = Color(0xFF842CD3);

  // ─── Divider ─────────────────────────────────────────────
  static const Color divider = Color(0xFF1A1A1A);

  // ─── Aliases de conveniência ──────────────────────────────
  static const Color onSurfaceMuted = Color(0xFF767575);
  static const Color surfaceHigh = Color(0xFF20201F);
  static const Color surfaceHighest = Color(0xFF262626);
}
