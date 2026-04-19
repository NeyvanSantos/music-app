import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  group('SettingsNotifier Tests', () {
    test('Valores iniciais devem ser padrão', () {
      final state = container.read(settingsProvider);
      expect(state.isIncognito, isFalse);
      expect(state.dynamicBackground, isTrue);
      expect(state.smartQueue, isTrue);
    });

    test('toggleIncognito deve atualizar estado', () async {
      await container.read(settingsProvider.notifier).toggleIncognito();
      expect(container.read(settingsProvider).isIncognito, isTrue);
      expect(prefs.getBool('settings_is_incognito'), isTrue);
    });

    test('toggleDynamicBackground deve entrar em loop toggle', () async {
      await container.read(settingsProvider.notifier).toggleDynamicBackground();
      expect(container.read(settingsProvider).dynamicBackground, isFalse);

      await container.read(settingsProvider.notifier).toggleDynamicBackground();
      expect(container.read(settingsProvider).dynamicBackground, isTrue);
    });

    test('toggleSmartQueue deve atualizar estado', () async {
      await container.read(settingsProvider.notifier).toggleSmartQueue();
      expect(container.read(settingsProvider).smartQueue, isFalse);
    });

    test('togglePreferVideo deve atualizar estado e persistir', () async {
      final notifier = container.read(settingsProvider.notifier);

      await notifier.togglePreferVideo();
      expect(container.read(settingsProvider).preferVideo, isTrue);
      expect(prefs.getBool('settings_prefer_video'), isTrue);

      await notifier.togglePreferVideo();
      expect(container.read(settingsProvider).preferVideo, isFalse);
      expect(prefs.getBool('settings_prefer_video'), isFalse);
    });

    test('setPreviewChannel deve persistir canal preview', () async {
      final notifier = container.read(settingsProvider.notifier);

      await notifier.setPreviewChannel(true);
      expect(container.read(settingsProvider).isPreviewChannel, isTrue);
      expect(prefs.getString('update_channel'), 'preview');

      await notifier.setPreviewChannel(false);
      expect(container.read(settingsProvider).isPreviewChannel, isFalse);
      expect(prefs.getString('update_channel'), 'stable');
    });
  });
}
