import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:music_app/features/player/presentation/providers/player_provider.dart';

/// Mini Player flutuante global — aparece em todas as telas quando há música tocando.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta apenas se há uma música para decidir se o player aparece
    final hasSong = ref.watch(playerProvider.select((s) => s.currentSong != null));
    if (!hasSong) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/player'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _MiniPlayerArtwork(),
                  SizedBox(width: 12),
                  Expanded(child: _MiniPlayerInfo()),
                  _MiniPlayerControls(),
                ],
              ),
            ),
            _MiniPlayerProgressBar(),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayerArtwork extends StatelessWidget {
  const _MiniPlayerArtwork();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainerHigh,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Icon(Icons.music_note_rounded, color: AppColors.primary, size: 18),
    );
  }
}

class _MiniPlayerInfo extends ConsumerWidget {
  const _MiniPlayerInfo();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerProvider.select((s) => s.currentSong));
    if (song == null) return const SizedBox.shrink();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        Text(
          song.artist,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant, letterSpacing: 1),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MiniPlayerControls extends ConsumerWidget {
  const _MiniPlayerControls();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => ref.read(playerProvider.notifier).previous(),
          child: const Icon(Icons.skip_previous_rounded, color: AppColors.onSurfaceVariant, size: 22),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => ref.read(playerProvider.notifier).togglePlay(),
          child: Container(
            width: 34, height: 34,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.onPrimary, size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => ref.read(playerProvider.notifier).next(),
          child: const Icon(Icons.skip_next_rounded, color: AppColors.onSurfaceVariant, size: 22),
        ),
      ],
    );
  }
}

class _MiniPlayerProgressBar extends ConsumerWidget {
  const _MiniPlayerProgressBar();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(playerProvider.select((s) => s.progress));
    final duration = ref.watch(playerProvider.select((s) => s.duration));
    
    final factor = duration.inSeconds > 0 
        ? (progress.inSeconds / duration.inSeconds).clamp(0.0, 1.0) 
        : 0.0;

    return Positioned(
      bottom: 0, left: 32, right: 32,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: AppColors.surfaceBright.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: factor,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
