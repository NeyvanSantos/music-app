import 'package:music_app/core/models/song_model.dart';

/// Define os modos de repetição do player.
enum PlayerRepeatMode { off, all, one }

/// Define o estado global do player de música.
class PlayerState {
  final SongModel? currentSong;
  final bool isPlaying;
  final Duration progress;
  final Duration duration;
  final double volume;
  final List<SongModel> queue;
  final int currentIndex;
  final bool isShuffleEnabled;
  final PlayerRepeatMode repeatMode;

  const PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.progress = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.queue = const [],
    this.currentIndex = -1,
    this.isShuffleEnabled = false,
    this.repeatMode = PlayerRepeatMode.off,
  });

  PlayerState copyWith({
    SongModel? currentSong,
    bool? isPlaying,
    Duration? progress,
    Duration? duration,
    double? volume,
    List<SongModel>? queue,
    int? currentIndex,
    bool? isShuffleEnabled,
    PlayerRepeatMode? repeatMode,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}
