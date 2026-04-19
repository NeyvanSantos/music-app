import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:music_app/features/player/presentation/providers/player_provider.dart';
import 'package:music_app/features/library/presentation/providers/library_providers.dart';
import 'package:music_app/features/player/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SongOptionsBottomSheet extends ConsumerWidget {
  final SongModel song;

  const SongOptionsBottomSheet({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoriteSongsProvider.select(
      (s) => s.any((e) => e.id == song.id),
    ));

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 24),

            // Info da Música
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: song.thumbnailUrl ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(color: Colors.white10, height: 1),

            // Opções
            _buildMenuItem(
              context,
              icon: Icons.play_arrow_rounded,
              title: 'Tocar Agora',
              onTap: () {
                Navigator.pop(context);
                ref.read(playerProvider.notifier).setSong(song);
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.playlist_play_rounded,
              title: 'Tocar em Seguida',
              onTap: () {
                Navigator.pop(context);
                ref.read(playerProvider.notifier).playNext(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Adicionado para tocar em seguida')),
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.queue_music_rounded,
              title: 'Adicionar à Fila',
              onTap: () {
                Navigator.pop(context);
                ref.read(playerProvider.notifier).addToQueue(song);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Adicionado ao final da fila')),
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.playlist_add_rounded,
              title: 'Colocar na Playlist',
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => AddToPlaylistSheet(song: song),
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: isFav
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              title: isFav ? 'Remover das Favoritas' : 'Favoritar',
              iconColor: isFav ? AppColors.primary : Colors.white,
              onTap: () {
                ref.read(libraryControllerProvider).toggleFavorite(song);
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
