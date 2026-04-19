/// Constantes globais do aplicativo.
///
/// Valores reutilizáveis que não mudam em tempo de execução.
abstract class AppConstants {
  AppConstants._();

  // ─── App Info ────────────────────────────────────────────
  static const String appName = 'Music App';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Premium Music Streaming';

  // ─── Durations (animações) ───────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animVerySlow = Duration(milliseconds: 800);

  // ─── Layout ──────────────────────────────────────────────
  static const double maxContentWidth = 600;
  static const double miniPlayerHeight = 72;
  static const double bottomNavHeight = 80;

  // ─── Limites ─────────────────────────────────────────────
  static const int maxSearchResults = 50;
  static const int maxRecentHistory = 20;
  static const int maxQueueSize = 500;
}
