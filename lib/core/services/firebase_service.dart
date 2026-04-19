import 'package:firebase_core/firebase_core.dart';
import 'package:music_app/firebase_options.dart';

/// Serviço de inicialização do Firebase.
///
/// Centraliza a configuração e inicialização do Firebase
/// para manter o main.dart limpo e organizado.
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;

  /// Inicializa o Firebase com as opções geradas pelo FlutterFire CLI.
  ///
  /// Este método é idempotente — chamar múltiplas vezes é seguro.
  static Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _initialized = true;
  }

  /// Retorna true se o Firebase já foi inicializado.
  static bool get isInitialized => _initialized;
}
