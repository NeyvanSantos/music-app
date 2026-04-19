import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/features/player/domain/models/player_state.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/main.dart'; // Para acessar o audioHandler global

/// Provedor global para o estado do player de música.
final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(() {
  return PlayerNotifier();
});

class PlayerNotifier extends Notifier<PlayerState> {
  Timer? _positionTimer;
  bool _isSeeking = false;

  @override
  PlayerState build() {
    final handler = audioHandler;
    if (handler != null) {
      // Configura os Callbacks de Sistema (Sincronia Nativa v11)
      // Fazemos isso apenas uma vez na build para garantir que a barra de notificação
      // saiba o que fazer quando os botões nativos forem clicados.
      handler.onSkipNext = () => next();
      handler.onSkipPrevious = () => previous();

      // Escuta mudanças de estado (play/pause/error)
      handler.playbackState.listen((playbackState) {
        if (state.isPlaying != playbackState.playing) {
          state = state.copyWith(isPlaying: playbackState.playing);
        }

        // Fila Inteligente: Avanço automático ao completar
        if (playbackState.processingState == AudioProcessingState.completed) {
          next();
        }

        // Auto-Skip em caso de erro (Estabilização v11)
        if (playbackState.processingState == AudioProcessingState.error) {
          debugPrint('SOMX_PLAYER: 🚨 Erro detectado no stream. Tentando pular em 2s...');
          Future.delayed(const Duration(seconds: 2), () {
            // Verifica se ainda está em estado de erro para evitar skips duplicados
            if (audioHandler?.playbackState.value.processingState == AudioProcessingState.error) {
              next();
            }
          });
        }
      });

      // Escuta mudanças de mediaItem para pegar a duração
      handler.mediaItem.listen((mediaItem) {
        if (mediaItem != null && mediaItem.duration != null) {
          if (state.duration != mediaItem.duration) {
            state = state.copyWith(duration: mediaItem.duration);
          }
        }
      });
    }

    // Limpa o timer quando o provider for descartado
    ref.onDispose(() {
      _positionTimer?.cancel();
    });

    return const PlayerState();
  }

  /// Inicia um timer periódico que lê posição e duração do VideoPlayerController
  void _startPositionSync() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_isSeeking) return;

      final controller = audioHandler?.controller;
      if (controller == null || !controller.value.isInitialized) return;

      final position = controller.value.position;
      final duration = controller.value.duration;

      // Atualiza duração se mudou
      if (duration != Duration.zero && state.duration != duration) {
        state = state.copyWith(duration: duration);
      }

      // Atualiza posição se mudou (evita rebuild desnecessário)
      if ((position.inMilliseconds - state.progress.inMilliseconds).abs() > 400) {
        state = state.copyWith(progress: position);
      }
    });
  }

  /// Define a música atual e inicia o player.
  void setSong(SongModel song, {List<SongModel>? newQueue}) {
    final queue = newQueue ?? [song];
    final index = queue.indexOf(song);

    state = state.copyWith(
      currentSong: song,
      queue: queue,
      currentIndex: index >= 0 ? index : 0,
      isPlaying: true,
      progress: Duration.zero,
      duration: Duration.zero,
    );

    // Inicia no serviço de áudio
    audioHandler?.loadSong(song);

    // Inicia a sincronização de posição em tempo real
    _startPositionSync();
  }

  /// Alterna entre Play e Pause.
  void togglePlay() {
    if (state.currentSong == null) return;
    if (state.isPlaying) {
      pause();
    } else {
      resume();
    }
  }

  /// Pausa a música no serviço de áudio.
  void pause() {
    state = state.copyWith(isPlaying: false);
    audioHandler?.pause();
  }

  /// Retoma a música no serviço de áudio.
  void resume() {
    state = state.copyWith(isPlaying: true);
    audioHandler?.play();
  }

  /// Avança para a próxima música na fila.
  void next() {
    if (state.queue.isEmpty) return;

    // Se o shuffle estiver ativo, escolhemos uma música aleatória da fila
    if (state.isShuffleEnabled && state.queue.length > 1) {
      int nextRandomIndex;
      do {
        nextRandomIndex = Random().nextInt(state.queue.length);
      } while (nextRandomIndex == state.currentIndex);
      
      final nextSong = state.queue[nextRandomIndex];
      setSong(nextSong, newQueue: state.queue);
      return;
    }

    final nextIndex = state.currentIndex + 1;
    if (nextIndex < state.queue.length) {
      final nextSong = state.queue[nextIndex];
      setSong(nextSong, newQueue: state.queue);
    } else {
      // Se chegamos no fim da fila e o RepeatMode for ALL, voltamos pro início
      if (state.repeatMode == PlayerRepeatMode.all) {
        setSong(state.queue.first, newQueue: state.queue);
      }
    }
  }

  /// Volta para a música anterior.
  void previous() {
    if (state.queue.isEmpty) return;

    final prevIndex = state.currentIndex - 1;
    if (prevIndex >= 0) {
      final prevSong = state.queue[prevIndex];
      setSong(prevSong, newQueue: state.queue);
    } else {
      // Se estamos no início e o RepeatMode for ALL, vamos pra última
      if (state.repeatMode == PlayerRepeatMode.all) {
        setSong(state.queue.last, newQueue: state.queue);
      }
    }
  }

  /// Alterna o estado do Shuffle.
  void toggleShuffle() {
    final newState = !state.isShuffleEnabled;
    state = state.copyWith(isShuffleEnabled: newState);
    audioHandler?.setShuffleMode(
      newState ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
  }

  /// Alterna o estado do Repeat (Off -> All -> One).
  void toggleRepeat() {
    final currentMode = state.repeatMode;
    PlayerRepeatMode nextMode;
    AudioServiceRepeatMode serviceMode;

    switch (currentMode) {
      case PlayerRepeatMode.off:
        nextMode = PlayerRepeatMode.all;
        serviceMode = AudioServiceRepeatMode.all;
        break;
      case PlayerRepeatMode.all:
        nextMode = PlayerRepeatMode.one;
        serviceMode = AudioServiceRepeatMode.one;
        break;
      case PlayerRepeatMode.one:
        nextMode = PlayerRepeatMode.off;
        serviceMode = AudioServiceRepeatMode.none;
        break;
    }

    state = state.copyWith(repeatMode: nextMode);
    audioHandler?.setRepeatMode(serviceMode);
  }

  /// Atualiza o progresso visual (para arrastar o slider sem pular o áudio).
  void updateProgress(Duration progress) {
    _isSeeking = true;
    state = state.copyWith(progress: progress);
  }

  /// Atualiza a duração total da mídia.
  void updateDuration(Duration duration) {
    state = state.copyWith(duration: duration);
  }

  /// Define o volume.
  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  /// Pula para uma posição específica na música.
  Future<void> seekTo(Duration position) async {
    state = state.copyWith(progress: position);
    await audioHandler?.seek(position);
    _isSeeking = false;
  }

  /// Reordena as músicas na fila de reprodução.
  void reorderQueue(int oldIndex, int newIndex) {
    final currentQueue = [...state.queue];
    
    // Ajuste necessário para o comportamento do ReorderableListView do Flutter
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final song = currentQueue.removeAt(oldIndex);
    currentQueue.insert(newIndex, song);
    
    // Encontra o novo índice da música atual dentro da nova fila
    int newCurrentIndex = state.currentIndex;
    if (state.currentSong != null) {
      newCurrentIndex = currentQueue.indexOf(state.currentSong!);
    }
    
    state = state.copyWith(
      queue: currentQueue,
      currentIndex: newCurrentIndex,
    );
  }

  /// Adiciona uma música para tocar logo após a atual.
  void playNext(SongModel song) {
    final currentQueue = [...state.queue];
    final nextIndex = state.currentIndex + 1;
    
    // Remove se já existir na fila para evitar duplicatas próximas
    currentQueue.removeWhere((s) => s.id == song.id);
    
    // Insere na próxima posição
    final targetIndex = nextIndex.clamp(0, currentQueue.length);
    currentQueue.insert(targetIndex, song);
    
    state = state.copyWith(queue: currentQueue);
  }

  /// Adiciona uma música ao final da fila de reprodução.
  void addToQueue(SongModel song) {
    final currentQueue = [...state.queue];
    
    // Evita adicionar a mesma música se já estiver na fila (opcional, dependendo da UX desejada)
    if (!currentQueue.any((s) => s.id == song.id)) {
      currentQueue.add(song);
      state = state.copyWith(queue: currentQueue);
    }
  }
}

