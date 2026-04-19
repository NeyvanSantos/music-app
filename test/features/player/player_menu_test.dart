import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/player/presentation/widgets/player_menu_bottom_sheet.dart';
import 'package:music_app/features/player/presentation/providers/sleep_timer_provider.dart';

void main() {
  Widget createTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: PlayerMenuBottomSheet(),
        ),
      ),
    );
  }

  group('PlayerMenuBottomSheet Widget Tests', () {
    testWidgets('Deve exibir todos os itens principais do menu',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Temporizador'), findsOneWidget);
      expect(find.text('Adicionar à Playlist'), findsOneWidget);
      expect(find.text('Equalizador'), findsOneWidget);
    });

    testWidgets(
        'Deve abrir diálogo de seleção de tempo ao clicar em Temporizador',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Temporizador'));
      await tester.pumpAndSettle();

      expect(find.text('Parar música em...'), findsOneWidget);
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
    });

    testWidgets('Deve mostrar estado ativo se o timer estiver rodando',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sleepTimerProvider.overrideWith(() => SleepTimerNotifierFake(10)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PlayerMenuBottomSheet(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Faltam 10 min'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}

class SleepTimerNotifierFake extends Notifier<SleepTimerState>
    implements SleepTimerNotifier {
  final int mins;
  SleepTimerNotifierFake(this.mins);

  @override
  SleepTimerState build() =>
      SleepTimerState(remainingMinutes: mins, isActive: true);

  @override
  void setTimer(int minutes) {}
  @override
  void cancelTimer() {}
}
