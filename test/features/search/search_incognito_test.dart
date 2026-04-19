import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/search/presentation/providers/search_history_provider.dart';
import 'package:music_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:music_app/core/providers/shared_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Search History Incognito Tests', () {
    test('Não deve adicionar ao histórico se Modo Incógnito estiver ativo', () async {
      // 1. Ativa Modo Incógnito
      await container.read(settingsProvider.notifier).toggleIncognito();
      expect(container.read(settingsProvider).isIncognito, isTrue);

      // 2. Tenta adicionar uma busca
      await container.read(searchHistoryProvider.notifier).addEntry('Musica Secreta');

      // 3. Verifica que o histórico continua vazio
      final history = container.read(searchHistoryProvider);
      expect(history, isEmpty);
    });

    test('Deve adicionar ao histórico se Modo Incógnito estiver desativado', () async {
      // 1. Garante que Modo Incógnito está desativado
      expect(container.read(settingsProvider).isIncognito, isFalse);

      // 2. Adiciona uma busca
      await container.read(searchHistoryProvider.notifier).addEntry('Musica Normal');

      // 3. Verifica que o histórico foi populado
      final history = container.read(searchHistoryProvider);
      expect(history, isNotEmpty);
      expect(history.first.query, 'Musica Normal');
    });
  });
}
