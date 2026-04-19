import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:music_app/core/constants/api_keys.dart';
import 'package:music_app/core/models/song_model.dart';

class DownloadProxyService {
  DownloadProxyService._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiKeys.downloadProxyBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  static bool get isConfigured =>
      ApiKeys.downloadProxyBaseUrl.trim().isNotEmpty;

  static Future<DownloadProxyResult> downloadSongToFile(
    SongModel song,
    File destinationFile, {
    void Function(int received, int total)? onProgress,
  }) async {
    if (!isConfigured) {
      throw const DownloadProxyException(
        'Proxy de download nao configurado no app.',
      );
    }

    final job = await _createJob(song);
    final status = await _waitForReadyJob(job.jobId);
    final fileUrl = status.downloadUrl;
    if (fileUrl == null || fileUrl.isEmpty) {
      throw const DownloadProxyException(
        'Backend concluiu o job sem URL de download.',
      );
    }

    if (await destinationFile.exists()) {
      await destinationFile.delete();
    }

    await _dio.downloadUri(
      Uri.parse(fileUrl),
      destinationFile.path,
      onReceiveProgress: onProgress,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
      ),
    );

    return DownloadProxyResult(
      container: _inferContainer(status.contentType, fileUrl),
      fromCache: status.fromCache ?? job.fromCache,
    );
  }

  static Future<_CreateDownloadJobResponse> _createJob(SongModel song) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/downloads',
        data: <String, dynamic>{
          'song': song.toMap(),
        },
      );

      final data = response.data;
      final jobId = data?['jobId']?.toString();
      if (jobId == null || jobId.isEmpty) {
        throw const DownloadProxyException('Backend nao retornou jobId.');
      }
      return _CreateDownloadJobResponse(
        jobId: jobId,
        fromCache: data?['cached'] == true,
      );
    } on DioException catch (e) {
      throw DownloadProxyException(_extractBackendMessage(e));
    }
  }

  static Future<_DownloadJobStatus> _waitForReadyJob(String jobId) async {
    final startedAt = DateTime.now();

    while (true) {
      final status = await _fetchJob(jobId);

      switch (status.state) {
        case 'completed':
          if (status.downloadUrl == null || status.downloadUrl!.isEmpty) {
            throw const DownloadProxyException(
              'Backend concluiu o job sem URL de download.',
            );
          }
          return status;
        case 'failed':
          throw DownloadProxyException(
            status.errorMessage ?? 'Falha no backend de download.',
          );
        case 'queued':
        case 'processing':
          if (DateTime.now().difference(startedAt) >
              const Duration(minutes: 3)) {
            throw const DownloadProxyException(
              'Backend demorou mais do que o esperado para processar o download.',
            );
          }
          await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  static Future<_DownloadJobStatus> _fetchJob(String jobId) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/downloads/$jobId');
      return _DownloadJobStatus.fromMap(
          response.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw DownloadProxyException(_extractBackendMessage(e));
    }
  }

  static String _extractBackendMessage(DioException error) {
    final payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      final message = payload['error']?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Timeout ao falar com o backend de download.';
    }

    return error.message ?? 'Falha ao falar com o backend de download.';
  }

  static String _inferContainer(String? contentType, String url) {
    final normalizedContentType = contentType?.toLowerCase() ?? '';
    if (normalizedContentType.contains('mpeg')) return 'mp3';
    if (normalizedContentType.contains('mp4')) return 'm4a';
    if (normalizedContentType.contains('webm')) return 'webm';
    if (normalizedContentType.contains('aac')) return 'aac';

    final uri = Uri.parse(url);
    final lastSegment =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last.toLowerCase() : '';
    if (lastSegment.endsWith('.mp3')) return 'mp3';
    if (lastSegment.endsWith('.m4a')) return 'm4a';
    if (lastSegment.endsWith('.webm')) return 'webm';
    if (lastSegment.endsWith('.aac')) return 'aac';

    return 'mp3';
  }
}

class DownloadProxyException implements Exception {
  final String message;

  const DownloadProxyException(this.message);

  @override
  String toString() => message;
}

class DownloadProxyResult {
  final String container;
  final bool fromCache;

  const DownloadProxyResult({
    required this.container,
    required this.fromCache,
  });
}

class _CreateDownloadJobResponse {
  final String jobId;
  final bool fromCache;

  const _CreateDownloadJobResponse({
    required this.jobId,
    required this.fromCache,
  });
}

class _DownloadJobStatus {
  final String state;
  final String? downloadUrl;
  final String? contentType;
  final String? errorMessage;
  final bool? fromCache;

  const _DownloadJobStatus({
    required this.state,
    this.downloadUrl,
    this.contentType,
    this.errorMessage,
    this.fromCache,
  });

  factory _DownloadJobStatus.fromMap(Map<String, dynamic> map) {
    return _DownloadJobStatus(
      state: map['status']?.toString() ?? 'queued',
      downloadUrl: map['downloadUrl']?.toString(),
      contentType: map['contentType']?.toString(),
      errorMessage: map['error']?.toString(),
      fromCache: map['cached'] is bool ? map['cached'] as bool : null,
    );
  }
}
