import 'package:audio_service/audio_service.dart';
import 'package:video_player/video_player.dart';
import 'package:music_app/core/services/youtube_service.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:flutter/foundation.dart';

class MusicHandler extends BaseAudioHandler with QueueHandler {
  VideoPlayerController? _videoPlayerController;
  DateTime? _lastUpdate;
  bool _isInitialized = false;

  VideoPlayerController? get controller => _videoPlayerController;
  bool get isInitialized => _isInitialized;

  /// Callbacks para integrar com o playerProvider
  VoidCallback? onSkipNext;
  VoidCallback? onSkipPrevious;

  @override
  Future<void> play() async {
    if (_videoPlayerController == null) return;
    await _videoPlayerController!.play();
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
    ));
  }

  @override
  Future<void> pause() async {
    if (_videoPlayerController == null) return;
    await _videoPlayerController!.pause();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
    ));
  }

  @override
  Future<void> skipToNext() async {
    onSkipNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onSkipPrevious?.call();
  }

  @override
  Future<void> stop() async {
    if (_videoPlayerController != null) {
      await _videoPlayerController!.pause();
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    return super.stop();
  }

  /// Chamado pelo Android quando o app é deslizado (fechado) na lista de tarefas
  @override
  Future<void> onTaskRemoved() async {
    debugPrint(
        'SOMX_HANDLER: App fechado pelo usuário. Parando serviço de áudio...');
    await stop();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> seek(Duration position) async {
    if (_videoPlayerController == null) return;
    await _videoPlayerController!.seekTo(position);
  }

  /// Carrega e inicia uma nova música
  Future<void> loadSong(SongModel song) async {
    try {
      _isInitialized = false;

      // Cleanup do anterior
      if (_videoPlayerController != null) {
        _videoPlayerController!.removeListener(_onControllerUpdate);
        await _videoPlayerController!.dispose();
      }

      String currentId = song.id;

      // Se a música for estática (veio do fallback/dashboard), buscamos o VideoID real
      if (currentId.startsWith('search:')) {
        final query = currentId.substring(7); // Remove 'search:'
        final results = await YouTubeService.searchSongs(query);
        if (results.isNotEmpty) {
          currentId = results.first.id;
        } else {
          throw Exception('Could not find real YouTube ID for static song');
        }
      }

      final streamUrl = await YouTubeService.getStreamUrl(currentId).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout ao obter link do YouTube'),
      );

      if (streamUrl == null) throw Exception('Link de áudio não disponível');

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
      );

      await _videoPlayerController!.initialize().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout ao inicializar player'),
          );

      _videoPlayerController!.addListener(_onControllerUpdate);

      mediaItem.add(MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        duration: _videoPlayerController!.value.duration,
        artUri:
            song.thumbnailUrl != null ? Uri.parse(song.thumbnailUrl!) : null,
      ));

      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.ready,
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
        playing: true,
      ));

      _isInitialized = true;
      await _videoPlayerController!.play();
    } catch (e) {
      debugPrint('SOMX_ERROR: Erro fatal no AudioHandler: $e');
      _isInitialized = false;

      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
      ));
    }
  }

  void _onControllerUpdate() {
    if (_videoPlayerController == null) return;

    final now = DateTime.now();
    final isFinished = _videoPlayerController!.value.position >=
            _videoPlayerController!.value.duration &&
        _videoPlayerController!.value.duration != Duration.zero;

    // Sincroniza estado com o sistema
    if (_lastUpdate == null ||
        now.difference(_lastUpdate!) > const Duration(seconds: 1) ||
        isFinished) {
      _lastUpdate = now;

      playbackState.add(playbackState.value.copyWith(
        updatePosition: _videoPlayerController!.value.position,
        bufferedPosition: _videoPlayerController!.value.buffered.isNotEmpty
            ? _videoPlayerController!.value.buffered.last.end
            : Duration.zero,
      ));

      if (isFinished) {
        // Se o modo de repetição for 'one', reiniciamos a música atual imediatamente
        if (playbackState.value.repeatMode == AudioServiceRepeatMode.one) {
          seek(Duration.zero);
          play();
        } else {
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.completed,
          ));
        }
      }
    }
  }
}
