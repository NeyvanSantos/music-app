import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:music_app/features/player/presentation/providers/player_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class QueueBottomSheet extends ConsumerWidget {
  const QueueBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final queue = playerState.queue;
    final currentIndex = playerState.currentIndex;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.queue_music_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Fila de Reprodução',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: queue.isEmpty
                  ? const Center(
                      child: Text(
                        'A fila está vazia',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: queue.length,
                      onReorder: (oldIndex, newIndex) {
                        ref.read(playerProvider.notifier).reorderQueue(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final song = queue[index];
                        final isPlaying = index == currentIndex;

                        return ListTile(
                          key: ValueKey('queue_${song.id}_$index'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: song.thumbnailUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: song.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: Colors.white10),
                                      errorWidget: (_, __, ___) => Container(
                                        color: Colors.white10,
                                        child: const Icon(Icons.music_note, color: Colors.white54),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.white10,
                                      child: const Icon(Icons.music_note, color: Colors.white54),
                                    ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                              color: isPlaying ? AppColors.primary : Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isPlaying ? AppColors.primary.withValues(alpha: 0.7) : Colors.white54,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPlaying)
                                const Icon(Icons.bar_chart_rounded, color: AppColors.primary)
                              else
                                IconButton(
                                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white54),
                                  onPressed: () {
                                    ref.read(playerProvider.notifier).setSong(song, newQueue: queue);
                                  },
                                ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.drag_handle_rounded,
                                color: Colors.white24,
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!isPlaying) {
                              ref.read(playerProvider.notifier).setSong(song, newQueue: queue);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
