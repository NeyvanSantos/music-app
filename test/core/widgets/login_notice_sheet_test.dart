import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/widgets/login_notice_sheet.dart';

void main() {
  group('LoginNoticeSheet Widget Tests', () {
    testWidgets('Deve exibir o aviso de login corretamente', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => Scaffold(body: Builder(builder: (context) => ElevatedButton(onPressed: () => LoginNoticeSheet.show(context), child: const Text('Mostrar'))))),
          GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('Página de Login'))),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Abre o sheet
      await tester.tap(find.text('Mostrar'));
      await tester.pumpAndSettle();

      // Verifica conteúdos
      expect(find.text('Ação Exclusiva para Membros'), findsOneWidget);
      expect(find.text('Para salvar suas músicas favoritas e criar playlists personalizadas, você precisa entrar na sua conta.'), findsOneWidget);
      expect(find.text('Entrar Agora'), findsOneWidget);
      expect(find.text('Continuar como Convidado'), findsOneWidget);
    });

    testWidgets('Deve fechar ao clicar em Continuar como Convidado', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => Scaffold(body: Builder(builder: (context) => ElevatedButton(onPressed: () => LoginNoticeSheet.show(context), child: const Text('Mostrar'))))),
          GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('Página de Login'))),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('Mostrar'));
      await tester.pumpAndSettle();

      // Clica em Continuar como Convidado (chama context.pop())
      await tester.tap(find.text('Continuar como Convidado'));
      await tester.pumpAndSettle();

      // Verifica se o sheet sumiu
      expect(find.text('Ação Exclusiva para Membros'), findsNothing);
    });
    
    testWidgets('Deve navegar para login ao clicar em Entrar Agora', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => Scaffold(body: Builder(builder: (context) => ElevatedButton(onPressed: () => LoginNoticeSheet.show(context), child: const Text('Mostrar'))))),
          GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('Página de Login'))),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('Mostrar'));
      await tester.pumpAndSettle();

      // Clica em Entrar Agora (chama context.pop() e context.go('/login'))
      await tester.tap(find.text('Entrar Agora'));
      await tester.pumpAndSettle();

      // Verifica se navegou para a página de login
      expect(find.text('Página de Login'), findsOneWidget);
    });
  });
}
