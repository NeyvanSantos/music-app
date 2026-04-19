import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/theme/app_colors.dart';

import 'package:music_app/core/models/song_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/library/presentation/providers/library_providers.dart';
import 'package:music_app/features/player/presentation/providers/player_provider.dart';
import 'package:music_app/core/providers/auth_provider.dart';
import 'package:music_app/core/widgets/login_notice_sheet.dart';
import 'package:music_app/features/home/presentation/providers/trending_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Section ─────────────────────────────
          SliverToBoxAdapter(
            child: _HeroSection(),
          ),

          // ─── Curtida Recentemente ──────────────────────
          const SliverToBoxAdapter(
            child: _RecentlyLikedSection(),
          ),

          // ─── Ranking / Recently Played ────────────────
          const SliverToBoxAdapter(
            child: _RecentlyPlayedGrid(),
          ),

          // ─── Gêneros ──────────────────────────────────
          const _GenreSlivers(),

          // Padding bottom
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}

/// Widget interno para gerenciar os slivers de gêneros de forma isolada.
class _GenreSlivers extends ConsumerWidget {
  const _GenreSlivers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genreAsync = ref.watch(genreTopSongsProvider);

    return genreAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
                SizedBox(height: 12),
                Text('Carregando Top 10...',
                    style: TextStyle(
                        color: AppColors.onSurfaceMuted, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('Não foi possível carregar os rankings.',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
        ),
      ),
      data: (genreMap) {
        final entries = genreMap.entries.toList();
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = entries[index ~/ 2];
              final isHeader = index % 2 == 0;
              final genre = entry.key;
              final songs = entry.value;
              final color = _genreColors[genre] ?? AppColors.primary;

              if (songs.isEmpty) return const SizedBox.shrink();

              if (isHeader) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          genre,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Top 10',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemExtent: 130, // Otimização de layout fixo
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: songs.length,
                    itemBuilder: (context, idx) {
                      final song = songs[idx];
                      return _GenreSongCard(
                        song: song,
                        index: idx + 1,
                        accentColor: color,
                        onTap: () {
                          ref
                              .read(playerProvider.notifier)
                              .setSong(song, newQueue: songs);
                          context.push('/player');
                        },
                      );
                    },
                  ),
                );
              }
            },
            childCount: entries.length * 2,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CURTIDA RECENTEMENTE — Última Música Curtida
// ═══════════════════════════════════════════════════════════

class _RecentlyLikedSection extends ConsumerWidget {
  const _RecentlyLikedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteSongsProvider);

    if (favorites.isEmpty) return const SizedBox.shrink();

    final lastLiked = favorites.first;
    final thumbUrl = lastLiked.thumbnailUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Curtida Recentemente',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              ref
                  .read(playerProvider.notifier)
                  .setSong(lastLiked, newQueue: favorites);
              context.push('/player');
            },
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail de fundo
                    if (thumbUrl != null && thumbUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.surface),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.music_note,
                              color: AppColors.onSurfaceMuted, size: 48),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.surface,
                        child: const Icon(Icons.music_note,
                            color: AppColors.onSurfaceMuted, size: 48),
                      ),

                    // Gradiente escuro para legibilidade
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),

                    // Título e Artista abaixo
                    Positioned(
                      left: 16,
                      right: 60,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lastLiked.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastLiked.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botão Play
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.black, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HERO SECTION — Carrossel Dinâmico de Trending
// ═══════════════════════════════════════════════════════════

class _HeroSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends ConsumerState<_HeroSection> {
  late final PageController _pageController;
  int _currentPage = 0;
  late final Duration _autoPlayDuration;

  // Cores de fundo para cada slide do carrossel
  static const _slideGradients = [
    [Color(0xFF1A3A2A), Color(0xFF0D1F17)], // Verde escuro
    [Color(0xFF2A1A3A), Color(0xFF170D1F)], // Roxo escuro
    [Color(0xFF3A2A1A), Color(0xFF1F170D)], // Dourado escuro
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _autoPlayDuration = const Duration(seconds: 5);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    Future.delayed(_autoPlayDuration, () {
      if (!mounted) return;
      final trending = ref.read(trendingMusicProvider);
      final data =
          trending is AsyncData<List<SongModel>> ? trending.value : null;
      final totalPages = data?.length ?? 1;
      if (totalPages <= 1) {
        _startAutoPlay();
        return;
      }

      final int nextPage = ((_currentPage + 1) % totalPages).toInt();
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
      _startAutoPlay();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingMusicProvider);

    return trendingAsync.when(
      loading: () => _buildShimmer(),
      error: (_, __) => _buildFallback(),
      data: (songs) {
        if (songs.isEmpty) return _buildFallback();
        return _buildCarousel(songs);
      },
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                AppColors.surfaceContainerLow,
                AppColors.background,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Carregando tendências...',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDim.withValues(alpha: 0.3),
                AppColors.background,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note_rounded,
                    size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(
                  'Explore músicas na busca',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(List<SongModel> songs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: _pageController,
              itemCount: songs.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final song = songs[index];
                final gradient =
                    _slideGradients[index % _slideGradients.length];
                return _buildSlide(song, gradient, songs);
              },
            ),
          ),
          const SizedBox(height: 12),
          // ─── Indicadores de Página ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(songs.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isActive
                      ? AppColors.primary
                      : AppColors.onSurfaceMuted.withValues(alpha: 0.3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(
      SongModel song, List<Color> gradient, List<SongModel> allSongs) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Imagem de Fundo (Thumbnail) ────────────
          CachedNetworkImage(
            imageUrl: song.effectiveThumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.album_rounded,
                  size: 64,
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),

          // ─── Gradiente de Escurecimento ─────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // ─── Conteúdo do Slide ─────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tag \"Em Alta\"
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '🔥  EM ALTA',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Título da Música
                  Text(
                    song.title,
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Artista
                  Text(
                    song.artist,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  // Botões
                  Row(
                    children: [
                      // Ouvir Agora
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(playerProvider.notifier)
                              .setSong(song, newQueue: allSongs);
                          context.push('/player');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDim],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primaryDim.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_arrow_rounded,
                                  color: AppColors.onPrimary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Ouvir Agora',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Botão Adicionar
                      Consumer(
                        builder: (context, ref, child) {
                          return GestureDetector(
                            onTap: () {
                              final isGuest = ref.read(isGuestProvider);
                              if (isGuest) {
                                LoginNoticeSheet.show(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Em breve: Adicionar à sua biblioteca')),
                                );
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceBright
                                    .withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 18),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final String trailing;

  const _SectionHeader({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            trailing,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// RECENTLY PLAYED GRID
// ═══════════════════════════════════════════════════════════

class _RecentlyPlayedGrid extends ConsumerWidget {
  const _RecentlyPlayedGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(favoriteSongsProvider);

    if (songs.isEmpty) return const SizedBox.shrink();

    final highlight = songs.first;
    final list = songs.skip(1).take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Highlighted track (large)
          GestureDetector(
            onTap: () {
              ref
                  .read(playerProvider.notifier)
                  .setSong(highlight, newQueue: songs);
              context.push('/player');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: highlight.effectiveThumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.surfaceContainerHigh),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceContainerHigh,
                          child: Icon(Icons.music_note_rounded,
                              color: AppColors.primary.withValues(alpha: 0.3),
                              size: 48),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    highlight.title,
                    style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    highlight.artist,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Small track list
          ...list.map((track) => _TrackRow(track: track)),
        ],
      ),
    );
  }
}

class _TrackRow extends ConsumerWidget {
  final SongModel track;
  const _TrackRow({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(playerProvider.notifier).setSong(track);
        context.push('/player');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: track.effectiveThumbnailUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.surfaceContainerHigh),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_outline_rounded,
                color: AppColors.onSurfaceVariant, size: 24),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GENRE DATA & CARD
// ═══════════════════════════════════════════════════════════

const Map<String, Color> _genreColors = {
  'FUNK': Color(0xFFFF3CAC),
  'PAGODE': Color(0xFFFFD700),
  'SERTANEJO': Color(0xFF00C853),
  'POP': Color(0xFF448AFF),
};

class _GenreSongCard extends StatelessWidget {
  final SongModel song;
  final int index;
  final Color accentColor;
  final VoidCallback onTap;

  const _GenreSongCard({
    required this.song,
    required this.index,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 140,
                    width: 140,
                    decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerHigh),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: song.effectiveThumbnailUrl,
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: AppColors.surfaceContainerHigh),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.2),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      '#$index',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Icon(Icons.play_arrow_rounded,
                        color: accentColor, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
