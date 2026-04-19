import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/models/song_model.dart';

// Cache simples de músicas para recuperar por ID
class SongsCacheNotifier extends Notifier<Map<String, SongModel>> {
  @override
  Map<String, SongModel> build() {
    return {};
  }

  void addSong(SongModel song) {
    state = {...state, song.id: song};
  }

  void addSongs(List<SongModel> songs) {
    final newMap = {...state};
    for (final song in songs) {
      newMap[song.id] = song;
    }
    state = newMap;
  }

  SongModel? getSong(String id) {
    return state[id];
  }

  List<SongModel> getSongs(List<String> ids) {
    return ids.map((id) => state[id]).whereType<SongModel>().toList();
  }
}

final songsCacheProvider =
    NotifierProvider<SongsCacheNotifier, Map<String, SongModel>>(() {
  return SongsCacheNotifier();
});

void cacheSongLater(Ref ref, SongModel song) {
  Future<void>.microtask(() {
    ref.read(songsCacheProvider.notifier).addSong(song);
  });
}

void cacheSongsLater(Ref ref, List<SongModel> songs) {
  if (songs.isEmpty) {
    return;
  }

  Future<void>.microtask(() {
    ref.read(songsCacheProvider.notifier).addSongs(songs);
  });
}
