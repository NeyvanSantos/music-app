import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/providers/auth_provider.dart';
import 'package:music_app/core/providers/shared_prefs_provider.dart';
import 'package:music_app/features/settings/presentation/widgets/settings_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier mockado para controlar o estado de convidado nos testes.
class MockGuestNotifier extends GuestNotifier {
  final bool initialValue;

  MockGuestNotifier(this.initialValue);

  @override
  bool build() => initialValue;
}

/// Notifier mockado para evitar chamadas reais ao AuthService/Firebase.
class MockAuthController extends AuthController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  @override
  Future<void> signOut() async {}
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({
    bool isGuest = false,
    bool hasPreviewAccess = true,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isGuestProvider.overrideWith(() => MockGuestNotifier(isGuest)),
        authControllerProvider.overrideWith(() => MockAuthController()),
        previewAccessProvider.overrideWith((ref) => hasPreviewAccess),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SettingsBottomSheet(),
        ),
      ),
    );
  }

  group('SettingsBottomSheet Widget Tests', () {
    testWidgets('Deve exibir titulo e secoes principais', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('PREFERÊNCIAS'), findsOneWidget);
      expect(find.text('ARMAZENAMENTO'), findsOneWidget);
      expect(find.text('CONTA'), findsOneWidget);
    });

    testWidgets('Deve exibir todos os switches de preferencia', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Modo Incógnito'), findsOneWidget);
      expect(find.text('Fundo Dinâmico'), findsOneWidget);
      expect(find.text('Fila Inteligente'), findsOneWidget);
      expect(find.text('Canal Preview'), findsOneWidget);
    });

    testWidgets('Nao deve exibir Canal Preview sem permissao', (tester) async {
      await tester.pumpWidget(createTestWidget(hasPreviewAccess: false));

      expect(find.text('Canal Preview'), findsNothing);
      expect(find.textContaining('Canal atual:'), findsNothing);
    });

    testWidgets('Deve permitir alternar os switches', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Modo Incógnito'));
      await tester.pump();

      expect(prefs.getBool('settings_is_incognito'), isTrue);
    });

    testWidgets('Deve disparar acao ao clicar em Limpar Cache', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Limpar Cache'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Limpar Cache'), findsOneWidget);
    });

    testWidgets('Deve alternar canal preview e persistir preferencia', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Canal Preview'));
      await tester.pumpAndSettle();

      expect(prefs.getString('update_channel'), 'preview');
      expect(find.textContaining('Canal atual: preview'), findsOneWidget);
    });

    testWidgets('Deve exibir opcao de Migrar para usuarios convidados', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(isGuest: true));
      expect(find.text('Migrar para Conta Google'), findsOneWidget);
    });

    testWidgets('Deve exibir opcao de Sair para usuarios logados', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(isGuest: false));
      expect(find.text('Sair da Conta'), findsOneWidget);
    });
  });
}
