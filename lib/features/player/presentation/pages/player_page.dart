import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/services/local_storage_service.dart';
import 'package:music_app/core/services/song_download_service.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:music_app/features/player/presentation/providers/player_provider.dart';
import 'package:music_app/features/player/domain/models/player_state.dart';
import 'package:music_app/features/player/presentation/widgets/youtube_video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/features/library/presentation/providers/library_providers.dart';
import 'package:music_app/features/player/presentation/providers/player_background_provider.dart';
import 'package:music_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:music_app/features/player/presentation/widgets/player_menu_bottom_sheet.dart';
import 'package:music_app/features/player/presentation/widgets/queue_bottom_sheet.dart';

final downloadedSongsProvider =
    NotifierProvider<DownloadedSongsNotifier, List<SongModel>>(
  DownloadedSongsNotifier.new,
);

final downloadingSongsProvider =
    NotifierProvider<DownloadingSongsNotifier, Set<String>>(
  DownloadingSongsNotifier.new,
);

final downloadProgressProvider =
    NotifierProvider<DownloadProgressNotifier, Map<String, double>>(
  DownloadProgressNotifier.new,
);

class DownloadedSongsNotifier extends Notifier<List<SongModel>> {
  @override
  List<SongModel> build() => LocalStorageService.getDownloads();

  void upsert(SongModel song) {
    state = [
      song,
      ...state.where((item) => item.id != song.id),
    ];
  }
}

class DownloadingSongsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void add(String songId) {
    state = {...state, songId};
  }

  void remove(String songId) {
    state = Set<String>.from(state)..remove(songId);
  }
}

class DownloadProgressNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() => <String, double>{};

  void set(String songId, double progress) {
    state = {...state, songId: progress};
  }

  void clear(String songId) {
    state = Map<String, double>.from(state)..remove(songId);
  }
}

class PlayerPage extends ConsumerWidget {
  final SongModel? song;

  const PlayerPage({super.key, this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    final playerState = ref.watch(playerProvider);
    final currentSong = playerState.currentSong ?? song;
    final isPlaying = playerState.isPlaying;

    // Fundo Dinâmico
    final dynamicColor =
        ref.watch(playerBackgroundProvider).value ?? AppColors.primary;

    // Feedback de Erro (Estabilização v11)
    ref.listen(playerProvider, (previous, next) {
      if (next.duration == Duration.zero &&
          previous?.duration != next.duration &&
          !next.isPlaying &&
          next.currentSong != null) {
        // Aqui poderíamos ter uma checagem mais específica,
        // mas vamos usar o processState do audioHandler via provider no futuro.
        // Por enquanto, o Auto-Skip no Provider já lida com o erro silencioso.
      }

      // Se detectarmos falha crítica via logs do sistema (SOMX_ERROR)
    });

    if (currentSong == null) {
      return const Scaffold(
        body: Center(child: Text('Nenhuma música selecionada')),
      );
    }

    final title = currentSong.title;
    final artist = currentSong.artist;
    final isYouTube = currentSong.source == SongSource.youtube;
    final downloadedSongs = ref.watch(downloadedSongsProvider);
    final isDownloaded =
        downloadedSongs.any((song) => song.id == currentSong.id);
    final downloadingSongs = ref.watch(downloadingSongsProvider);
    final isDownloading = downloadingSongs.contains(currentSong.id);
    final progressMap = ref.watch(downloadProgressProvider);
    final downloadProgress = progressMap[currentSong.id] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ─── Background Glow (Dynamic) ──────
          Positioned(
            top: size.height * 0.2,
            left: size.width * 0.05,
            right: size.width * 0.05,
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              height: size.width * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dynamicColor.withValues(alpha: 0.15),
                    blurRadius: 180,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // ─── Top Bar ────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Icon(
                                  Icons.expand_more_rounded,
                                  color: AppColors.onSurfaceVariant,
                                  size: 32,
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    'TOCANDO AGORA',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurfaceVariant,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    'Somax',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    barrierColor: Colors.black45,
                                    isScrollControlled: true,
                                    builder: (context) =>
                                        const PlayerMenuBottomSheet(),
                                  );
                                },
                                icon: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceContainerHigh
                                        .withValues(alpha: 0.5),
                                  ),
                                  child: const Icon(
                                    Icons.more_vert_rounded,
                                    color: AppColors.onSurface,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ─── Distribuição Vertical ──────────────────
                        const Spacer(flex: 2),

                        // ─── Video/Music Toggle ─────────────────────
                        const _VideoMusicToggle(),

                        const SizedBox(height: 24),

                        // ─── Media Container (Adaptativo) ───────────
                        Flexible(
                          flex: 10,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.4),
                                        blurRadius: 40,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: isYouTube &&
                                            currentSong.youtubeId != null &&
                                            ref
                                                .watch(settingsProvider)
                                                .preferVideo
                                        ? YouTubeVideoPlayer(
                                            song: currentSong,
                                            autoPlay: true,
                                          )
                                        : (currentSong.thumbnailUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl:
                                                    currentSong.thumbnailUrl!,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              )
                                            : const Center(
                                                child: Icon(
                                                  Icons.album_rounded,
                                                  size: 80,
                                                  color: AppColors
                                                      .onSurfaceVariant,
                                                ),
                                              )),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 2),

                        // ─── Track Info (Centralizado) ──────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.manrope(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.onSurface,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      artist,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, child) {
                                  final favorites =
                                      ref.watch(favoriteSongsProvider);
                                  final isFav = favorites
                                      .any((s) => s.id == currentSong.id);

                                  return GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(libraryControllerProvider)
                                          .toggleFavorite(currentSong);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        isFav
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: isFav
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant,
                                        size: 28,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ─── Progress Bar ───────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor:
                                      AppColors.surfaceContainerHighest,
                                  thumbColor: Colors.white,
                                  overlayColor:
                                      AppColors.primary.withValues(alpha: 0.2),
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14),
                                  trackShape:
                                      const RoundedRectSliderTrackShape(),
                                ),
                                child: Slider(
                                  value: playerState.duration.inSeconds > 0
                                      ? playerState.progress.inSeconds
                                          .toDouble()
                                          .clamp(
                                              0.0,
                                              playerState.duration.inSeconds
                                                  .toDouble())
                                      : 0.0,
                                  min: 0.0,
                                  max: playerState.duration.inSeconds > 0
                                      ? playerState.duration.inSeconds
                                          .toDouble()
                                      : 1.0,
                                  onChanged: (val) {
                                    ref
                                        .read(playerProvider.notifier)
                                        .updateProgress(
                                            Duration(seconds: val.toInt()));
                                  },
                                  onChangeEnd: (val) {
                                    ref
                                        .read(playerProvider.notifier)
                                        .seekTo(Duration(seconds: val.toInt()));
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(playerState.progress),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(playerState.duration),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ─── Main Controls ──────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(
                                  playerState.isShuffleEnabled
                                      ? Icons.shuffle_on_rounded
                                      : Icons.shuffle_rounded,
                                ),
                                color: playerState.isShuffleEnabled
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                                onPressed: () => ref
                                    .read(playerProvider.notifier)
                                    .toggleShuffle(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded),
                                color: AppColors.onSurface,
                                iconSize: 42,
                                onPressed: () => ref
                                    .read(playerProvider.notifier)
                                    .previous(),
                              ),
                              GestureDetector(
                                onTap: () => ref
                                    .read(playerProvider.notifier)
                                    .togglePlay(),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 40,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: AppColors.onPrimary,
                                    size: 48,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded),
                                color: AppColors.onSurface,
                                iconSize: 42,
                                onPressed: () =>
                                    ref.read(playerProvider.notifier).next(),
                              ),
                              IconButton(
                                icon: Icon(
                                  playerState.repeatMode == PlayerRepeatMode.one
                                      ? Icons.repeat_one_on_rounded
                                      : (playerState.repeatMode ==
                                              PlayerRepeatMode.all
                                          ? Icons.repeat_on_rounded
                                          : Icons.repeat_rounded),
                                ),
                                color: playerState.repeatMode !=
                                        PlayerRepeatMode.off
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                                onPressed: () => ref
                                    .read(playerProvider.notifier)
                                    .toggleRepeat(),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 2),

                        // ─── Utility Bar ────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isDownloading
                                      ? Icons.downloading_rounded
                                      : (isDownloaded
                                          ? Icons.download_done_rounded
                                          : Icons.download_rounded),
                                ),
                                color: isDownloading || isDownloaded
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                                iconSize: 22,
                                onPressed: (!isYouTube ||
                                        isDownloading ||
                                        isDownloaded)
                                    ? null
                                    : () async {
                                        final downloadingNotifier = ref.read(
                                          downloadingSongsProvider.notifier,
                                        );
                                        final progressNotifier = ref.read(
                                          downloadProgressProvider.notifier,
                                        );

                                        downloadingNotifier.add(currentSong.id);
                                        progressNotifier.set(currentSong.id, 0);

                                        try {
                                          final downloadResult =
                                              await SongDownloadService
                                                  .downloadSong(
                                            currentSong,
                                            onProgress: (received, total) {
                                              if (total <= 0) return;
                                              progressNotifier.set(
                                                currentSong.id,
                                                received / total,
                                              );
                                            },
                                          );

                                          ref
                                              .read(downloadedSongsProvider
                                                  .notifier)
                                              .upsert(downloadResult.song);

                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                downloadResult.fromCache
                                                    ? 'Musica baixada do cache com sucesso.'
                                                    : 'Musica baixada com sucesso.',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                SongDownloadService
                                                    .toUserMessage(e),
                                              ),
                                            ),
                                          );
                                        } finally {
                                          downloadingNotifier
                                              .remove(currentSong.id);
                                          progressNotifier
                                              .clear(currentSong.id);
                                        }
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.playlist_play_rounded),
                                color: AppColors.onSurfaceVariant,
                                iconSize: 28,
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    barrierColor: Colors.black54,
                                    isScrollControlled: true,
                                    builder: (context) =>
                                        const QueueBottomSheet(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        if (isDownloading)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: downloadProgress > 0
                                      ? downloadProgress
                                      : null,
                                  minHeight: 3,
                                  backgroundColor:
                                      AppColors.surfaceContainerHighest,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Baixando musica... ${(downloadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _VideoMusicToggle extends ConsumerWidget {
  const _VideoMusicToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isVideo = settings.preferVideo;

    return Container(
      width: 160,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          // Indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: isVideo ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 80,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Buttons
          Row(
            children: [
              _buildButton(
                context,
                label: 'Música',
                isSelected: !isVideo,
                onTap: () {
                  if (isVideo) {
                    ref.read(settingsProvider.notifier).togglePreferVideo();
                  }
                },
              ),
              _buildButton(
                context,
                label: 'Vídeo',
                isSelected: isVideo,
                onTap: () {
                  if (!isVideo) {
                    ref.read(settingsProvider.notifier).togglePreferVideo();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
