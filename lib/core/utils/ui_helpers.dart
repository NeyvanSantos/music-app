import 'package:flutter/material.dart';

/// Utilitarios de UI reutilizaveis.
abstract class UIHelpers {
  UIHelpers._();

  /// Exibe um SnackBar estilizado.
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Verifica se a tela e considerada "wide" (tablet/desktop).
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768;
  }

  /// Verifica se a largura e compacta, comum em celulares menores.
  static bool isCompactWidth(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Verifica se a altura disponivel e curta.
  static bool isShortHeight(BuildContext context) {
    return MediaQuery.of(context).size.height < 760;
  }

  /// Retorna padding horizontal responsivo.
  static double responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 64;
    if (width >= 768) return 32;
    if (width >= 390) return 24;
    return 16;
  }

  /// Escala um valor mantendo-o legivel em celulares pequenos.
  static double adaptiveValue(
    BuildContext context, {
    required double min,
    required double base,
    required double max,
  }) {
    final width = MediaQuery.of(context).size.width;
    final factor = (width / 390).clamp(0.85, 1.15);
    return (base * factor).clamp(min, max);
  }
}
