import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/search/presentation/providers/search_provider.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_app/features/player/presentation/providers/player_provider.dart';
import 'package:music_app/core/providers/auth_provider.dart';
import 'package:music_app/core/widgets/login_notice_sheet.dart';
import 'package:music_app/features/library/presentation/providers/library_providers.dart';
import 'package:music_app/features/search/presentation/providers/search_history_provider.dart';
import 'package:music_app/core/models/search_history_model.dart';
import 'package:music_app/features/player/presentation/widgets/song_options_bottom_sheet.dart';
import 'package:intl/intl.dart';

/// Search Screen — Nocturne.
///
/// Reproduz o design Stitch: barra de busca arredondada,
/// Top Suggestions em bento grid, Search History com ícones.
class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(youtubeSearchProvider(searchQuery));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Search Bar ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: TextField(
                    onChanged: (value) => ref
                        .read(searchQueryProvider.notifier)
                        .updateQuery(value),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        ref
                            .read(searchHistoryProvider.notifier)
                            .addEntry(value.trim());
                      }
                    },
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Artistas, músicas ou podcasts',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 20, right: 12),
                        child: Icon(
                          Icons.search_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const SizedBox(height: 16),

              if (searchQuery.isEmpty) ...[
                // Top Suggestions etc (os widgets abaixo)
              ] else
                searchResults.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Erro ao buscar: $error',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  data: (songs) => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return _YouTubeResultTile(
                        song: song,
                        allResults: songs,
                      );
                    },
                  ),
                ),

              const SizedBox(height: 40),

              if (searchQuery.isEmpty) ...[
                // Search History real
                Consumer(
                  builder: (context, ref, child) {
                    final history = ref.watch(searchHistoryProvider);
                    if (history.isEmpty) return const SizedBox.shrink();

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Histórico de Busca',
                                style: GoogleFonts.manrope(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => ref
                                    .read(searchHistoryProvider.notifier)
                                    .clearAll(),
                                child: Text(
                                  'Limpar Tudo',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...history.map((entry) => _HistoryItem(entry: entry)),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SUGGESTION CARD
// ═══════════════════════════════════════════════════════════

class _SuggestionCard extends StatelessWidget {
  final String title;
  final String artist;
  final Color color;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.title,
    required this.artist,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              artist,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HISTORY ITEM
// ═══════════════════════════════════════════════════════════

class _YouTubeResultTile extends ConsumerWidget {
  final SongModel song;
  final List<SongModel> allResults;

  const _YouTubeResultTile({required this.song, required this.allResults});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () {
        // Salva no histórico ao clicar
        ref.read(searchHistoryProvider.notifier).addEntry(
              song.title,
              type: 'Música',
            );
        ref.read(playerProvider.notifier).setSong(song, newQueue: allResults);
        context.push('/player', extra: song);
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: song.thumbnailUrl ?? '',
          width: 60,
          height: 60,
          memCacheWidth:
              120, // Otimização de memória: carrega apenas o dobro do tamanho exibido
          memCacheHeight: 120,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Container(color: AppColors.surfaceContainerLow),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
      title: Text(
        song.title,
        style: GoogleFonts.inter(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: GoogleFonts.inter(
          color: AppColors.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.onSurfaceVariant,
              size: 22,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => SongOptionsBottomSheet(song: song),
              );
            },
          ),
          const Icon(Icons.play_circle_fill,
              color: AppColors.primary, size: 28),
        ],
      ),
    );
  }
}

class _HistoryItem extends ConsumerWidget {
  final SearchHistoryEntry entry;

  const _HistoryItem({required this.entry});

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours} horas atrás';
    if (diff.inDays < 7) return '${diff.inDays} dias atrás';
    return DateFormat('dd/MM/yyyy').format(timestamp);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          ref.read(searchQueryProvider.notifier).updateQuery(entry.query);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.query,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '${entry.type} • ${_formatTime(entry.timestamp)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 18,
                ),
                onPressed: () => ref
                    .read(searchHistoryProvider.notifier)
                    .removeEntry(entry.query),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
