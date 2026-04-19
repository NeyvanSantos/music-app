import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/player/presentation/pages/player_page.dart';
import 'package:music_app/core/providers/shared_prefs_provider.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/features/player/presentation/widgets/youtube_video_player.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createTestWidget({SongModel? song}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: PlayerPage(song: song),
      ),
    );
  }

  final mockSong = SongModel(
    id: 'test_id',
    title: 'Test Song',
    artist: 'Test Artist',
    youtubeId: 'test_yt_id',
    source: SongSource.youtube,
    thumbnailUrl: 'https://test.com/thumb.jpg',
  );

  group('PlayerPage Layout Tests', () {
    testWidgets('Deve renderizar sem erros e mostrar thumbnail por padrão',
        (tester) async {
      await tester.pumpWidget(createTestWidget(song: mockSong));
      await tester.pump();

      expect(find.byType(PlayerPage), findsOneWidget);
      // Por padrão preferVideo é false, então deve mostrar a imagem
      expect(find.byType(AspectRatio), findsAtLeast(1));
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    });

    testWidgets('Deve alternar para modo vídeo sem quebrar o layout',
        (tester) async {
      await tester.pumpWidget(createTestWidget(song: mockSong));

      // Encontrar o botão "Vídeo" no toggle
      final videoButton = find.text('Vídeo');
      await tester.tap(videoButton);
      await tester.pump();
      await tester.pump(
          const Duration(milliseconds: 500)); // Esperar animação do toggle

      // Verificar se o YouTubeVideoPlayer apareceu
      expect(find.byType(YouTubeVideoPlayer), findsOneWidget);

      // Verificar se ainda temos o cabeçalho (garante que não houve crash total)
      expect(find.text('TOCANDO AGORA'), findsOneWidget);
    });
  });
}
