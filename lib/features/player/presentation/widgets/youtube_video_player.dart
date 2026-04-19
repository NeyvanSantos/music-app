import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:music_app/main.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class YouTubeVideoPlayer extends ConsumerStatefulWidget {
  final SongModel song;
  final bool autoPlay;

  const YouTubeVideoPlayer({
    super.key,
    required this.song,
    this.autoPlay = true,
  });

  @override
  ConsumerState<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends ConsumerState<YouTubeVideoPlayer> {
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _setupChewie();
  }

  @override
  void didUpdateWidget(YouTubeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _setupChewie();
    }
  }

  void _setupChewie() {
    // Se o handler ou controlador ainda não está pronto, esperamos
    if (audioHandler?.controller == null || audioHandler?.isInitialized != true) {
      _chewieController?.dispose();
      _chewieController = null;
      return;
    }

    _chewieController?.dispose();
    _chewieController = ChewieController(
      videoPlayerController: audioHandler!.controller!,
      autoPlay: widget.autoPlay,
      looping: false,
      aspectRatio: audioHandler!.controller!.value.aspectRatio,
      allowFullScreen: false,
      allowMuting: false,
      showControls: false,
      showOptions: false,
      draggableProgressBar: false,
      placeholder: _buildFallbackImage(),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.song.effectiveThumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.music_note_rounded,
              color: AppColors.onSurfaceVariant,
              size: 50,
            ),
          ),
          // Gradient escuro para o player
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Base Layer: Thumbnail (Always there) ─────
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: widget.song.effectiveThumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.music_note_rounded,
                color: AppColors.onSurfaceVariant,
                size: 50,
              ),
            ),
          ),
          
          // Dark overlay for consistency
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),

          // ─── Video Layer ────────────────────────────
          if (audioHandler != null)
            StreamBuilder<MediaItem?>(
              stream: audioHandler!.mediaItem,
              builder: (context, snapshot) {
                final currentMedia = snapshot.data;
                
                // Se a música atual no handler não é a deste widget, não mostramos vídeo
                if (currentMedia?.id != widget.song.id || audioHandler?.isInitialized != true) {
                  return const SizedBox.shrink();
                }

                if (_chewieController == null) {
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                     if (mounted) setState(() => _setupChewie());
                   });
                   return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                return Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Chewie(controller: _chewieController!),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
