import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/core/services/youtube_service.dart';
import 'package:music_app/core/providers/songs_cache_provider.dart';

// Provedor para o termo de busca atual
// No Riverpod 3.0, Notifier é preferido sobre StateProvider
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String newQuery) {
    state = newQuery;
  }
}

// Provedor de busca simplificado usando FutureProvider.family
final youtubeSearchProvider =
    FutureProvider.family<List<SongModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final songs = await YouTubeService.searchSongs(query);
  // Cache todas as músicas encontradas
  cacheSongsLater(ref, songs);
  return songs;
});
