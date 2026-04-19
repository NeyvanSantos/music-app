import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/library/presentation/providers/library_providers.dart';
import 'package:music_app/core/providers/auth_provider.dart';
import 'package:music_app/features/player/presentation/providers/player_provider.dart';
import 'package:music_app/core/models/song_model.dart';
import 'package:music_app/features/library/presentation/widgets/create_playlist_dialog.dart';

/// Library Screen — Nocturne.
///
/// Reproduz o design Stitch: Liked Songs card com gradiente roxo,
/// grid de playlists, e lista de músicas recentemente adicionadas.
/// Seção de Playlists Grid com rebuild isolado
class _PlaylistsGridSection extends ConsumerWidget {
  const _PlaylistsGridSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(userPlaylistsProvider);

    final children = <Widget>[
      Expanded(child: _NewPlaylistCard()),
      const SizedBox(width: 12),
    ];

    if (playlists.isNotEmpty) {
      children.add(
        Expanded(
          child: _PlaylistGridCard(
            id: playlists[0].id,
            title: playlists[0].name,
            subtitle: playlists[0].description ??
                '${playlists[0].songIds.length} músicas',
            color: Color(playlists[0].color ?? 0xFF3A2060),
            onTap: () {
              context.push('/playlist/${playlists[0].id}', extra: playlists[0]);
            },
          ),
        ),
      );
      children.add(const SizedBox(width: 12));
    }
    if (playlists.length > 1) {
      children.add(
        Expanded(
          child: _PlaylistGridCard(
            id: playlists[1].id,
            title: playlists[1].name,
            subtitle: playlists[1].description ??
                '${playlists[1].songIds.length} músicas',
            color: Color(playlists[1].color ?? 0xFF203050),
            onTap: () {
              context.push('/playlist/${playlists[1].id}', extra: playlists[1]);
            },
          ),
        ),
      );
    } else {
      children.add(const Expanded(child: SizedBox.shrink()));
      if (playlists.isEmpty) {
        children.add(const SizedBox(width: 12));
        children.add(const Expanded(child: SizedBox.shrink()));
      }
    }

    return Row(children: children);
  }
}

/// Seção de Músicas Recentes com rebuild isolado
class _RecentlyAddedSection extends ConsumerWidget {
  const _RecentlyAddedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteSongsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: favorites.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'Nenhuma música na biblioteca ainda.',
                  style: GoogleFonts.inter(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : Column(
              children: favorites.take(10).map((song) {
                return _RecentTrackItem(song: song);
              }).toList(),
            ),
    );
  }
}

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);

    if (isGuest) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: AppColors.primary,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Sua Biblioteca',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Faça login para salvar suas músicas favoritas e criar playlists personalizadas.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'FAZER LOGIN AGORA',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Section Header ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coleção Pessoal',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sua Biblioteca',
                          style: GoogleFonts.manrope(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Row(
                          children: [
                            _FilterChip(label: 'Playlists'),
                            SizedBox(width: 8),
                            _FilterChip(label: 'Álbuns'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Liked Songs Card (Gradient) ──────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _LikedSongsCard(),
              ),

              const SizedBox(height: 24),

              // ─── Your Playlists ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Suas Playlists',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Ver Todas',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => CreatePlaylistDialog.show(context),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: AppColors.primary,
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _PlaylistsGridSection(),
              ),

              const SizedBox(height: 40),

              // ─── Recently Added ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Adicionadas Recentemente',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Track List ───────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _RecentlyAddedSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FILTER CHIP
// ═══════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LIKED SONGS CARD
// ═══════════════════════════════════════════════════════════

class _LikedSongsCard extends ConsumerWidget {
  const _LikedSongsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesCount =
        ref.watch(favoriteSongsProvider.select((s) => s.length));

    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primary,
            AppColors.primaryDim,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background heart
          Positioned(
            top: 24,
            right: 24,
            child: Icon(
              Icons.favorite_rounded,
              size: 120,
              color: AppColors.onPrimary.withValues(alpha: 0.1),
            ),
          ),
          // Background glow
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Músicas Curtidas',
                  style: GoogleFonts.manrope(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$favoritesCount músicas salvas na sua coleção',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ouvir Coleção',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PLAYLIST GRID CARD
// ═══════════════════════════════════════════════════════════

class _PlaylistGridCard extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PlaylistGridCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
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
// NEW PLAYLIST CARD
// ═══════════════════════════════════════════════════════════

class _NewPlaylistCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => CreatePlaylistDialog.show(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Criar Nova',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Nova Playlist',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Começar do zero',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// RECENT TRACK ITEM
// ═══════════════════════════════════════════════════════════

class _RecentTrackItem extends ConsumerWidget {
  final SongModel song;

  const _RecentTrackItem({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        ref.read(playerProvider.notifier).setSong(song);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                image: song.effectiveThumbnailUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(song.effectiveThumbnailUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: song.effectiveThumbnailUrl.isEmpty
                  ? Icon(
                      Icons.music_note_rounded,
                      color: AppColors.primary.withValues(alpha: 0.4),
                      size: 22,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              color: AppColors.onSurfaceVariant,
              iconSize: 20,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
