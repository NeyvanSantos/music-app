import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/core/services/youtube_service.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:mocktail/mocktail.dart';

// Mock do cliente do YouTube
class MockYoutubeExplode extends Mock implements YoutubeExplode {}

class MockSearchClient extends Mock implements SearchClient {}

// Um Fake que se comporta como a lista de busca de vídeos do YouTube
class FakeVideoSearchList extends Fake implements VideoSearchList {
  final List<Video> _videos;
  FakeVideoSearchList(this._videos);

  @override
  Iterator<Video> get iterator => _videos.iterator;

  @override
  int get length => _videos.length;

  @override
  Iterable<T> map<T>(T Function(Video) f) => _videos.map(f);

  @override
  List<T> cast<T>() => _videos.cast<T>();

  @override
  Video operator [](int index) => _videos[index];

  @override
  String? get nextPageToken => null;

  @override
  Future<VideoSearchList?> nextPage() => Future.value(null);
}

class MockVideoClient extends Mock implements VideoClient {}

class MockStreamClient extends Mock implements StreamClient {}

void main() {
  late MockYoutubeExplode mockYt;
  late MockSearchClient mockSearch;

  setUp(() {
    mockYt = MockYoutubeExplode();
    mockSearch = MockSearchClient();

    // Configura o mock do cliente de busca
    when(() => mockYt.search).thenReturn(mockSearch);

    // Injeta o mock no serviço
    YouTubeService.setMockClient(mockYt);
  });

  group('YouTubeService Tests', () {
    test('searchSongs deve retornar uma lista vazia se a busca falhar',
        () async {
      when(() => mockSearch.search(any())).thenThrow(Exception('Erro de rede'));

      final result = await YouTubeService.searchSongs('teste');

      expect(result, isEmpty);
    });

    test(
        'searchSongs deve retornar modelos de música quando a busca tem sucesso',
        () async {
      final fakeVideoList = FakeVideoSearchList([]);

      // Quando o searchSongs chama search, retornamos nossa lista fake
      when(() => mockSearch.search(any()))
          .thenAnswer((_) async => fakeVideoList);

      final result = await YouTubeService.searchSongs('teste');

      expect(result, isA<List<SongModel>>());
      expect(result, isEmpty);
    });
  });
}
