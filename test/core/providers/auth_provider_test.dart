import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/providers/auth_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('isGuestProvider Tests (Notifier)', () {
    test('Deve inicializar como false', () {
      final isGuest = container.read(isGuestProvider);
      expect(isGuest, isFalse);
    });

    test('setGuest(true) deve atualizar o estado para true', () {
      container.read(isGuestProvider.notifier).setGuest(true);
      final isGuest = container.read(isGuestProvider);
      expect(isGuest, isTrue);
    });

    test('setGuest(false) deve atualizar o estado para false', () {
      // Primeiro seta true
      container.read(isGuestProvider.notifier).setGuest(true);
      expect(container.read(isGuestProvider), isTrue);

      // Depois seta false
      container.read(isGuestProvider.notifier).setGuest(false);
      expect(container.read(isGuestProvider), isFalse);
    });
  });

  group('AuthController Logic Tests', () {
    test('enterAsGuest deve ativar o modo convidado', () {
      container.read(authControllerProvider.notifier).enterAsGuest();
      expect(container.read(isGuestProvider), isTrue);
    });

    // Nota: O teste de signOut requer mock de AuthService/FirebaseAuth.
    // Como o foco é a estabilidade do bypass local, validamos que o enterAsGuest
    // está corretamente conectado ao notifier.
  });
}
