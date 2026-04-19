import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/core/services/download_proxy_service.dart';
import 'package:music_app/core/services/device_music_service.dart';
import 'package:music_app/core/services/youtube_service.dart';
import 'package:path_provider/path_provider.dart';

class SongDownloadService {
  SongDownloadService._();

  static final Dio _dio = Dio();

  static String toUserMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('requestlimitexceededexception') ||
        message.contains('rate limiting') ||
        message.contains('too many requests')) {
      return 'O YouTube bloqueou temporariamente este download. Tente novamente mais tarde ou troque de rede.';
    }

    if (message.contains('403')) {
      return 'O YouTube recusou o download desta musica. Tente novamente em alguns minutos.';
    }

    if (message.contains('timeout')) {
      return 'O download demorou mais do que o esperado. Tente novamente.';
    }

    if (message.contains('backend de download') ||
        message.contains('proxy de download')) {
      return 'O servidor de download nao respondeu como esperado. Tente novamente em instantes.';
    }

    if (message.contains('converter o audio para mp3')) {
      return 'O audio foi baixado, mas houve falha na conversao para MP3.';
    }

    return 'Nao foi possivel baixar esta musica agora. Tente novamente mais tarde.';
  }

  static Future<DownloadSongResult> downloadSong(
    SongModel song, {
    void Function(int received, int total)? onProgress,
  }) async {
    final tempDir = await _getTemporaryDownloadDirectory();
    final isYouTubeSource = song.source == SongSource.youtube &&
        (song.audioUrl == null || song.audioUrl!.trim().isEmpty);
    final sourceExtension =
        isYouTubeSource ? 'm4a' : _inferExtension(song.audioUrl?.trim() ?? '');

    final tempInputFile = File(
      '${tempDir.path}${Platform.pathSeparator}${_buildTempInputFileName(song, sourceExtension)}',
    );
    final mp3File = File(
      '${tempDir.path}${Platform.pathSeparator}${_buildFileName(song)}',
    );

    try {
      var downloadedFromCache = false;

      if (isYouTubeSource) {
        final youtubeId = song.youtubeId ?? song.id;
        final proxyResult = await _downloadYouTubeSource(
          song: song,
          youtubeId: youtubeId,
          tempInputFile: tempInputFile,
          onProgress: onProgress,
        );
        final container = proxyResult.container;
        downloadedFromCache = proxyResult.fromCache;

        if (container != sourceExtension) {
          final correctedInputFile = File(
            '${tempDir.path}${Platform.pathSeparator}${_buildTempInputFileName(song, _normalizeExtension(container))}',
          );
          if (await correctedInputFile.exists()) {
            await correctedInputFile.delete();
          }
          await tempInputFile.rename(correctedInputFile.path);
          return _finalizeDownload(
            song: song,
            inputFile: correctedInputFile,
            mp3File: mp3File,
            fromCache: downloadedFromCache,
          );
        }
      } else {
        final downloadUrl = _resolveDownloadUrl(song);
        await _downloadFromUrl(
          url: downloadUrl,
          destinationFile: tempInputFile,
          onProgress: onProgress,
        );
      }

      return _finalizeDownload(
        song: song,
        inputFile: tempInputFile,
        mp3File: mp3File,
        fromCache: false,
      );
    } finally {
      if (await tempInputFile.exists()) {
        await tempInputFile.delete();
      }
      if (DeviceMusicService.supportsNativeDeviceLibrary &&
          await mp3File.exists()) {
        await mp3File.delete();
      }
    }
  }

  static Future<DownloadProxyResult> _downloadYouTubeSource({
    required SongModel song,
    required String youtubeId,
    required File tempInputFile,
    void Function(int received, int total)? onProgress,
  }) async {
    if (DownloadProxyService.isConfigured) {
      try {
        return await DownloadProxyService.downloadSongToFile(
          song,
          tempInputFile,
          onProgress: onProgress,
        );
      } catch (_) {
        // O backend e opcional; mantemos o fluxo local como fallback.
      }
    }

    return DownloadProxyResult(
      container: await YouTubeService.downloadAudioStreamToFile(
        youtubeId,
        tempInputFile,
        onProgress: onProgress,
      ),
      fromCache: false,
    );
  }

  static Future<DownloadSongResult> _finalizeDownload({
    required SongModel song,
    required File inputFile,
    required File mp3File,
    required bool fromCache,
  }) async {
    final inputExtension = _normalizeExtension(inputFile.path.split('.').last);
    if (inputExtension == 'mp3') {
      if (await mp3File.exists()) {
        await mp3File.delete();
      }
      await inputFile.rename(mp3File.path);
    } else {
      await _convertToMp3(
        inputPath: inputFile.path,
        outputPath: mp3File.path,
      );
    }

    final audioUrl = await _storeDownloadedMp3(
      mp3File: mp3File,
      title: song.title,
      artist: song.artist,
    );

    final savedSong = song.copyWith(
      audioUrl: audioUrl,
      source: SongSource.local,
      createdAt: DateTime.now().toUtc(),
    );
    await DeviceMusicService.saveDownloadedSong(savedSong);
    return DownloadSongResult(song: savedSong, fromCache: fromCache);
  }

  static Future<Directory> _getPersistentDownloadDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}somax_downloads',
    );

    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    return downloadsDir;
  }

  static Future<Directory> _getTemporaryDownloadDirectory() async {
    final baseDir = await getTemporaryDirectory();
    final downloadsDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}somax_downloads',
    );

    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    return downloadsDir;
  }

  static String _resolveDownloadUrl(SongModel song) {
    final url = song.audioUrl?.trim();
    if (url == null || url.isEmpty) {
      throw Exception('Nao foi possivel obter o link de download da musica.');
    }
    return url;
  }

  static Future<void> _downloadFromUrl({
    required String url,
    required File destinationFile,
    void Function(int received, int total)? onProgress,
  }) async {
    await _dio.download(
      url,
      destinationFile.path,
      onReceiveProgress: onProgress,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
  }

  static Future<void> _convertToMp3({
    required String inputPath,
    required String outputPath,
  }) async {
    final session = await FFmpegKit.execute(
      '-y -i "${_escapePath(inputPath)}" -vn -codec:a libmp3lame -q:a 2 "${_escapePath(outputPath)}"',
    );
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final output = await session.getOutput();
      throw Exception(
        'Nao foi possivel converter o audio para mp3. ${output ?? ""}'.trim(),
      );
    }
  }

  static Future<String> _storeDownloadedMp3({
    required File mp3File,
    required String title,
    required String artist,
  }) async {
    if (DeviceMusicService.supportsNativeDeviceLibrary) {
      return DeviceMusicService.saveToPublicLibrary(
        tempFilePath: mp3File.path,
        title: title,
        artist: artist,
        originalUrl: mp3File.path,
      );
    }

    final downloadsDir = await _getPersistentDownloadDirectory();
    final destination = File(
      '${downloadsDir.path}${Platform.pathSeparator}${mp3File.uri.pathSegments.last}',
    );

    if (await destination.exists()) {
      await destination.delete();
    }

    await mp3File.copy(destination.path);
    return destination.path;
  }

  static String _buildFileName(SongModel song) {
    final sanitizedTitle = _sanitizeFileName(song.title);
    final sanitizedArtist = _sanitizeFileName(song.artist);
    return '${sanitizedArtist}_$sanitizedTitle.mp3';
  }

  static String _buildTempInputFileName(SongModel song, String extension) {
    final sanitizedTitle = _sanitizeFileName(song.title);
    final sanitizedArtist = _sanitizeFileName(song.artist);
    return '${sanitizedArtist}_$sanitizedTitle.source.$extension';
  }

  static String _sanitizeFileName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'somax_track' : cleaned;
  }

  static String _inferExtension(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path.toLowerCase() ?? '';
    if (path.endsWith('.mp3')) return 'mp3';
    if (path.endsWith('.m4a')) return 'm4a';
    if (path.endsWith('.aac')) return 'aac';
    if (path.endsWith('.webm')) return 'webm';
    if (path.endsWith('.mp4')) return 'mp4';
    return 'mp4';
  }

  static String _normalizeExtension(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'mp4') return 'm4a';
    if (normalized == 'm4a') return 'm4a';
    if (normalized == 'webm') return 'webm';
    if (normalized == 'mp3') return 'mp3';
    if (normalized == 'aac') return 'aac';
    return 'm4a';
  }

  static String _escapePath(String path) {
    return path.replaceAll('"', '\\"');
  }
}

class DownloadSongResult {
  final SongModel song;
  final bool fromCache;

  const DownloadSongResult({
    required this.song,
    required this.fromCache,
  });
}
