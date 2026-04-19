import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:music_app/features/library/presentation/providers/library_providers.dart';
import 'package:music_app/features/library/presentation/widgets/create_playlist_dialog.dart';

class AddToPlaylistSheet extends ConsumerWidget {
  final SongModel song;

  const AddToPlaylistSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(userPlaylistsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Adicionar à Playlist',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary),
            ),
            title: const Text('Criar nova playlist',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: () async {
              final playlistId = await CreatePlaylistDialog.show(context);
              if (playlistId != null && context.mounted) {
                await ref
                    .read(libraryControllerProvider)
                    .addSongToPlaylist(playlistId, song);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Criada e adicionada com sucesso!')),
                  );
                  Navigator.pop(context);
                }
              }
            },
          ),
          const Divider(color: Colors.white10),
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Você ainda não tem playlists localmente.\nCrie uma acima!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                final isAlreadyAdded = playlist.songIds.contains(song.id);

                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.playlist_play_rounded,
                        color: AppColors.primary),
                  ),
                  title: Text(playlist.name,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${playlist.songIds.length} músicas',
                      style: const TextStyle(color: Colors.white38)),
                  trailing: isAlreadyAdded
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.add_circle_outline,
                          color: Colors.white24),
                  onTap: isAlreadyAdded
                      ? null
                      : () async {
                          await ref
                              .read(libraryControllerProvider)
                              .addSongToPlaylist(playlist.id, song);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Adicionado a ${playlist.name}')),
                            );
                            Navigator.pop(context);
                          }
                        },
                );
              },
            ),
        ],
      ),
    );
  }
}
