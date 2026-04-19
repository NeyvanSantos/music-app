import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:mocktail/mocktail.dart';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Mocks
class MockVideo extends Mock implements Video {}
class MockVideoId extends Mock implements VideoId {}
class MockThumbnailSet extends Mock implements ThumbnailSet {}

void main() {
  group('SongModel Tests', () {
    test('Deve criar SongModel corretamente a partir de dados manuais', () {
      final song = SongModel(
        id: '1',
        title: 'Musica',
        artist: 'Artista',
        source: SongSource.local,
      );

      expect(song.id, '1');
      expect(song.title, 'Musica');
      expect(song.source, SongSource.local);
    });

    test('effectiveThumbnailUrl deve retornar URL do YouTube se thumbnailUrl for nulo', () {
      final song = SongModel(
        id: 'dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        artist: 'Rick Astley',
        source: SongSource.youtube,
      );

      expect(song.effectiveThumbnailUrl, contains('img.youtube.com'));
      expect(song.effectiveThumbnailUrl, contains('dQw4w9WgXcQ'));
    });

    test('effectiveThumbnailUrl deve retornar thumbnailUrl se ele existir', () {
      final song = SongModel(
        id: '1',
        title: 'Musica',
        artist: 'Artista',
        thumbnailUrl: 'https://minhafoto.com/foto.jpg',
      );

      expect(song.effectiveThumbnailUrl, 'https://minhafoto.com/foto.jpg');
    });
  });
}
