/// Utilitários de extensão para [String].
extension StringExtensions on String {
  /// Capitaliza a primeira letra da string.
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converte para título (Cada Palavra Capitalizada).
  String get titleCase {
    return split(' ').map((word) => word.capitalized).join(' ');
  }
}

/// Utilitários de extensão para [Duration].
extension DurationExtensions on Duration {
  /// Formata a duração como "mm:ss".
  String get formatted {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Formata a duração como "h:mm:ss" quando aplicável.
  String get formattedLong {
    if (inHours > 0) {
      final hours = inHours.toString();
      final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return formatted;
  }
}

/// Utilitários de extensão para [num].
extension NumExtensions on num {
  /// Formata número com separador de milhar (1.000, 10.000...).
  String get formatCompact {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    }
    if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toString();
  }
}
