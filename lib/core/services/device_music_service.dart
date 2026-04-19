import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/core/services/local_storage_service.dart';

class DeviceMusicService {
  DeviceMusicService._();

  static const MethodChannel _channel = MethodChannel('somax/device_music');

  static bool get supportsNativeDeviceLibrary => !kIsWeb && Platform.isAndroid;

  static bool get supportsImport => !supportsNativeDeviceLibrary;

  static Future<List<SongModel>> loadInternalSongs() async {
    if (supportsNativeDeviceLibrary) {
      final granted = await requestAudioPermission();
      final localDownloads = LocalStorageService.getDownloads();
      final localImports = LocalStorageService.getImportedSongs();
      final fallbackSongs = <SongModel>[
        ...localDownloads,
        ...localImports,
      ];

      if (!granted) {
        return _dedupeSongs(fallbackSongs);
      }

      final rawSongs = await _channel
              .invokeListMethod<Map<dynamic, dynamic>>('getDeviceSongs') ??
          <Map<dynamic, dynamic>>[];

      final deviceSongs = rawSongs
          .map(
            (item) => SongModel(
              id: (item['id'] ?? '').toString(),
              title: (item['title'] ?? 'Faixa sem nome').toString(),
              artist: (item['artist'] ?? 'Artista desconhecido').toString(),
              thumbnailUrl: null,
              audioUrl: (item['audioUrl'] ?? '').toString(),
              source: SongSource.local,
              createdAt: DateTime.now().toUtc(),
            ),
          )
          .where((song) => song.audioUrl != null && song.audioUrl!.isNotEmpty)
          .toList();

      return _dedupeSongs([
        ...deviceSongs,
        ...fallbackSongs,
      ]);
    }

    return _dedupeSongs([
      ...LocalStorageService.getDownloads(),
      ...LocalStorageService.getImportedSongs(),
    ]);
  }

  static Future<bool> requestAudioPermission() async {
    if (!supportsNativeDeviceLibrary) {
      return true;
    }

    final granted = await _channel.invokeMethod<bool>('requestAudioPermission');
    return granted ?? false;
  }

  static Future<String> saveToPublicLibrary({
    required String tempFilePath,
    required String title,
    required String artist,
    required String originalUrl,
  }) async {
    if (!supportsNativeDeviceLibrary) {
      throw UnsupportedError(
        'Download público de mídia está disponível apenas no Android.',
      );
    }

    final audioUrl = await _channel.invokeMethod<String>(
      'savePublicAudio',
      <String, dynamic>{
        'tempFilePath': tempFilePath,
        'title': title,
        'artist': artist,
        'originalUrl': originalUrl,
      },
    );

    if (audioUrl == null || audioUrl.isEmpty) {
      throw Exception(
          'Não foi possível registrar a música na biblioteca do aparelho.');
    }

    return audioUrl;
  }

  static Future<Map<String, String>> enqueueSystemAudioDownload({
    required String url,
    required String title,
    required String artist,
  }) async {
    if (!supportsNativeDeviceLibrary) {
      throw UnsupportedError(
        'Download pelo sistema está disponível apenas no Android.',
      );
    }

    final raw = await _channel.invokeMapMethod<dynamic, dynamic>(
      'enqueueSystemAudioDownload',
      <String, dynamic>{
        'url': url,
        'title': title,
        'artist': artist,
      },
    );

    if (raw == null) {
      throw Exception('Não foi possível iniciar o download pelo sistema.');
    }

    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  static Future<void> saveDownloadedSong(SongModel song) async {
    final current = LocalStorageService.getDownloads();
    final next = <SongModel>[song, ...current]
        .fold<List<SongModel>>(<SongModel>[], (acc, item) {
      final exists = acc.any(
        (existing) =>
            existing.audioUrl == item.audioUrl ||
            (existing.title == item.title && existing.artist == item.artist),
      );
      if (!exists) {
        acc.add(item);
      }
      return acc;
    });
    await LocalStorageService.saveDownloads(next);
  }

  static Future<List<SongModel>> importSongs() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const [
        'mp3',
        'm4a',
        'aac',
        'wav',
        'flac',
        'ogg',
        'mp4',
        'webm'
      ],
    );

    if (result == null || result.files.isEmpty) {
      return LocalStorageService.getImportedSongs();
    }

    final current = LocalStorageService.getImportedSongs();
    final next = <SongModel>[...current];

    for (final file in result.files) {
      final path = file.path;
      if (path == null || path.isEmpty) continue;

      final name = file.name;
      final title =
          name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;

      final song = SongModel(
        id: path,
        title: title,
        artist: 'Arquivo local',
        audioUrl: path,
        source: SongSource.local,
        createdAt: DateTime.now().toUtc(),
      );

      next.removeWhere((item) => item.id == song.id);
      next.insert(0, song);
    }

    await LocalStorageService.saveImportedSongs(next);
    return next;
  }

  static List<SongModel> _dedupeSongs(List<SongModel> songs) {
    final unique = <SongModel>[];
    for (final song in songs) {
      final alreadyIncluded = unique.any(
        (item) =>
            item.audioUrl == song.audioUrl ||
            (item.title == song.title && item.artist == song.artist),
      );
      if (!alreadyIncluded) {
        unique.add(song);
      }
    }
    return unique;
  }
}
