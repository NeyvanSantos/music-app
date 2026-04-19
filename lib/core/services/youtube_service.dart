import 'dart:async';
import 'dart:io';

import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/core/services/logger_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeService {
  static YoutubeExplode? _mockYt;

  static void setMockClient(YoutubeExplode mock) {
    _mockYt = mock;
  }

  static YoutubeExplode get _yt => _mockYt ?? YoutubeExplode();

  static Future<List<SongModel>> searchSongs(String query) async {
    final client = _yt;
    try {
      String refinedQuery = query.trim();
      final lowercaseQuery = refinedQuery.toLowerCase();

      final isAlbumOrPlaylist = lowercaseQuery.contains('album') ||
          lowercaseQuery.contains('discograf') ||
          lowercaseQuery.contains('playlist') ||
          lowercaseQuery.contains('full') ||
          lowercaseQuery.contains('completo') ||
          lowercaseQuery.contains('mix') ||
          lowercaseQuery.contains('setlist') ||
          lowercaseQuery.contains('ao vivo') ||
          lowercaseQuery.contains('live');

      if (!isAlbumOrPlaylist && refinedQuery.split(' ').length <= 4) {
        refinedQuery += ' song official audio';
      }

      final searchList = await client.search.search(refinedQuery);
      return searchList.map((video) => SongModel.fromYouTube(video)).toList();
    } catch (e, stackTrace) {
      LoggerService.error(
        'Erro na busca do YouTube.',
        error: e,
        stackTrace: stackTrace,
        tag: 'YOUTUBE',
      );
      return [];
    } finally {
      if (_mockYt == null) client.close();
    }
  }

  static Future<String?> getStreamUrl(String videoId) async {
    final client = _yt;
    try {
      final manifest = await client.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.muxed.withHighestBitrate();
      return streamInfo.url.toString();
    } catch (e, stackTrace) {
      LoggerService.error(
        'Erro ao obter stream do YouTube.',
        error: e,
        stackTrace: stackTrace,
        tag: 'YOUTUBE',
      );
      return null;
    } finally {
      if (_mockYt == null) client.close();
    }
  }

  static Future<String> downloadAudioStreamToFile(
    String videoId,
    File destinationFile, {
    void Function(int received, int total)? onProgress,
  }) async {
    final client = _yt;
    IOSink? output;

    try {
      final manifest = await client.videos.streamsClient.getManifest(
        videoId,
        ytClients: [
          YoutubeApiClient.ios,
          YoutubeApiClient.androidMusic,
          YoutubeApiClient.tv,
        ],
      );
      final audio = manifest.audioOnly.withHighestBitrate();
      final audioStream = client.videos.streamsClient.get(audio).timeout(
            const Duration(seconds: 20),
          );

      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }

      output = destinationFile.openWrite(mode: FileMode.writeOnly);

      final total = audio.size.totalBytes;
      var received = 0;

      await for (final chunk in audioStream) {
        received += chunk.length;
        output.add(chunk);
        onProgress?.call(received, total);
      }

      await output.flush();
      return audio.container.name;
    } catch (e, stackTrace) {
      LoggerService.error(
        'Erro ao baixar stream de audio do YouTube.',
        error: e,
        stackTrace: stackTrace,
        tag: 'YOUTUBE',
      );
      rethrow;
    } finally {
      await output?.close();
      if (_mockYt == null) client.close();
    }
  }

  static Future<List<SongModel>> getTrendingMusic({int count = 3}) async {
    final client = _yt;
    try {
      final searchList = await client.search.search(
        'top trending music songs ${DateTime.now().year}',
      );

      return searchList
          .take(count)
          .map((video) => SongModel.fromYouTube(video))
          .toList();
    } catch (e, stackTrace) {
      LoggerService.error(
        'Erro ao buscar trending.',
        error: e,
        stackTrace: stackTrace,
        tag: 'YOUTUBE',
      );
      return [];
    } finally {
      if (_mockYt == null) client.close();
    }
  }

  static void dispose() {
    _mockYt?.close();
  }
}
