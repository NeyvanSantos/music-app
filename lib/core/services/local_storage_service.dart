import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/core/models/playlist_model.dart';
import 'package:music_app/core/models/song_model.dart';

class LocalStorageService {
  static const String _playlistsKey = 'somax_local_playlists';
  static const String _favoritesKey = 'somax_local_favorites';
  static const String _downloadsKey = 'somax_local_downloads';
  static const String _importedSongsKey = 'somax_imported_local_songs';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Playlists ---

  static List<PlaylistModel> getPlaylists() {
    final String? json = _prefs?.getString(_playlistsKey);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => PlaylistModel.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> savePlaylists(List<PlaylistModel> playlists) async {
    final String json = jsonEncode(playlists.map((p) => p.toMap()).toList());
    await _prefs?.setString(_playlistsKey, json);
  }

  // --- Favorites (Músicas Curtidas) ---

  static List<SongModel> getFavorites() {
    final String? json = _prefs?.getString(_favoritesKey);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => SongModel.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveFavorites(List<SongModel> favorites) async {
    final String json = jsonEncode(favorites.map((s) => s.toMap()).toList());
    await _prefs?.setString(_favoritesKey, json);
  }

  static List<SongModel> getDownloads() {
    final String? json = _prefs?.getString(_downloadsKey);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => SongModel.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveDownloads(List<SongModel> downloads) async {
    final String json = jsonEncode(downloads.map((s) => s.toMap()).toList());
    await _prefs?.setString(_downloadsKey, json);
  }

  static List<SongModel> getImportedSongs() {
    final String? json = _prefs?.getString(_importedSongsKey);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => SongModel.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveImportedSongs(List<SongModel> songs) async {
    final String json = jsonEncode(songs.map((s) => s.toMap()).toList());
    await _prefs?.setString(_importedSongsKey, json);
  }
}
