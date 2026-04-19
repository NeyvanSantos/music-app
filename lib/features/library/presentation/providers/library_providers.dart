import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/models/playlist_model.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/core/providers/songs_cache_provider.dart';
import 'package:music_app/core/services/local_storage_service.dart';

/// Notifier para as Playlists do usuário salvas localmente.
class UserPlaylistsNotifier extends Notifier<List<PlaylistModel>> {
  @override
  List<PlaylistModel> build() {
    return LocalStorageService.getPlaylists();
  }

  Future<String> createPlaylist(String name,
      {String? description, int? color}) async {
    final playlist = PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      userId: 'local_user', // Playlists agora são locais e anônimas
      description: description,
      color: color,
      createdAt: DateTime.now(),
    );

    final newList = [playlist, ...state];
    state = newList;
    await LocalStorageService.savePlaylists(newList);
    return playlist.id;
  }

  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    final index = state.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      // Cache a música para recuperação posterior
      cacheSongLater(ref, song);

      final playlist = state[index];
      final currentIds = [...playlist.songIds];

      if (!currentIds.contains(song.id)) {
        currentIds.add(song.id);

        final updatedPlaylist = PlaylistModel(
          id: playlist.id,
          name: playlist.name,
          userId: playlist.userId,
          description: playlist.description,
          color: playlist.color,
          coverUrl: playlist.coverUrl,
          createdAt: playlist.createdAt,
          songIds: currentIds,
        );

        final newList = [...state];
        newList[index] = updatedPlaylist;
        state = newList;
        await LocalStorageService.savePlaylists(newList);
      }
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final newList = state.where((p) => p.id != playlistId).toList();
    state = newList;
    await LocalStorageService.savePlaylists(newList);
  }
}

final userPlaylistsProvider =
    NotifierProvider<UserPlaylistsNotifier, List<PlaylistModel>>(() {
  return UserPlaylistsNotifier();
});

/// Notifier para as Músicas Curtidas salvas localmente.
class FavoriteSongsNotifier extends Notifier<List<SongModel>> {
  @override
  List<SongModel> build() {
    final favorites = LocalStorageService.getFavorites();
    // Cache as músicas favoritas
    cacheSongsLater(ref, favorites);
    return favorites;
  }

  Future<void> toggleFavorite(SongModel song) async {
    final isFav = state.any((s) => s.id == song.id);
    List<SongModel> newList;

    if (isFav) {
      newList = state.where((s) => s.id != song.id).toList();
    } else {
      newList = [song, ...state];
    }

    state = newList;
    await LocalStorageService.saveFavorites(newList);
  }

  bool isFavorite(String songId) {
    return state.any((s) => s.id == songId);
  }
}

final favoriteSongsProvider =
    NotifierProvider<FavoriteSongsNotifier, List<SongModel>>(() {
  return FavoriteSongsNotifier();
});

/// Controller simplificado que apenas expõe as ações dos Notifiers
final libraryControllerProvider = Provider((ref) => LibraryController(ref));

class LibraryController {
  final Ref _ref;
  LibraryController(this._ref);

  // Redireciona para os novos Notifiers locais
  Future<String> createPlaylist(String name,
          {String? description, int? color}) =>
      _ref
          .read(userPlaylistsProvider.notifier)
          .createPlaylist(name, description: description, color: color);

  Future<void> addSongToPlaylist(String playlistId, SongModel song) => _ref
      .read(userPlaylistsProvider.notifier)
      .addSongToPlaylist(playlistId, song);

  Future<void> deletePlaylist(String playlistId) =>
      _ref.read(userPlaylistsProvider.notifier).deletePlaylist(playlistId);

  Future<void> toggleFavorite(SongModel song) =>
      _ref.read(favoriteSongsProvider.notifier).toggleFavorite(song);
}
