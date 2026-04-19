import 'dart:developer' as developer;

/// Serviço centralizado de logging.
///
/// Encapsula os logs para facilitar troca futura por Crashlytics,
/// Sentry ou qualquer outro serviço de telemetria.
abstract class LoggerService {
  LoggerService._();

  static void info(String message, {String? tag}) {
    developer.log('💡 $message', name: tag ?? 'INFO');
  }

  static void warning(String message, {String? tag}) {
    developer.log('⚠️ $message', name: tag ?? 'WARNING');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    developer.log(
      '❌ $message',
      name: tag ?? 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void debug(String message, {String? tag}) {
    assert(() {
      developer.log('🔍 $message', name: tag ?? 'DEBUG');
      return true;
    }());
  }
}
