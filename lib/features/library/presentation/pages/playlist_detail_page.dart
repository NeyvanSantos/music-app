import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/providers/songs_cache_provider.dart';
import 'package:music_app/core/models/playlist_model.dart';
import 'package:music_app/features/player/presentation/providers/player_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlaylistDetailPage extends ConsumerWidget {
  final PlaylistModel playlist;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Header ─────────────────────────────────────
          SliverAppBar(
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.onSurface,
              ),
            ),
            expandedHeight: 280,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                children: [
                  const SizedBox(height: 60),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Color(playlist.color ?? 0xFF3A2060),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(playlist.color ?? 0xFF3A2060)
                              .withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.music_note_rounded,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 80,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Playlist Info ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${playlist.songIds.length} música${playlist.songIds.length != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (playlist.description != null &&
                      playlist.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        playlist.description!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: playlist.songIds.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            size: 64,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma música nesta playlist',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Consumer(
                    builder: (context, ref, _) {
                      final cachedSongs = ref
                          .watch(songsCacheProvider.notifier)
                          .getSongs(playlist.songIds);

                      if (cachedSongs.isEmpty && playlist.songIds.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.music_note_rounded,
                                  size: 64,
                                  color: AppColors.onSurfaceVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma música salva ainda',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Adicione músicas a partir do player',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color:
                                        AppColors.onSurfaceVariant.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cachedSongs.length,
                        itemBuilder: (context, index) {
                          final song = cachedSongs[index];
                          final isCurrentSong =
                              ref.watch(playerProvider).currentSong?.id ==
                                  song.id;

                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: song.thumbnailUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: song.thumbnailUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                          Icons.music_note_rounded,
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.music_note_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                            ),
                            title: Text(
                              song.title,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: isCurrentSong
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isCurrentSong
                                    ? AppColors.primary
                                    : AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: AppColors.onSurfaceVariant,
                              ),
                              onPressed: () {
                                // Menu de opções
                              },
                            ),
                            onTap: () {
                              ref
                                  .read(playerProvider.notifier)
                                  .setSong(song, newQueue: cachedSongs);
                              context.push('/player', extra: song);
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}
