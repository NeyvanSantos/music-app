import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:music_app/features/player/presentation/providers/sleep_timer_provider.dart';
import 'package:music_app/features/player/presentation/providers/player_provider.dart';
import 'package:music_app/features/player/presentation/widgets/add_to_playlist_sheet.dart';

class PlayerMenuBottomSheet extends ConsumerWidget {
  const PlayerMenuBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(sleepTimerProvider);
    final currentSong = ref.watch(playerProvider).currentSong;

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

            // Item: Temporizador
            _buildMenuItem(
              context,
              icon: Icons.timer_outlined,
              title: 'Temporizador',
              subtitle: timerState.isActive
                  ? 'Faltam ${timerState.remainingMinutes} min'
                  : 'Desligamento automático',
              onTap: () => _showTimerOptions(context, ref),
              trailing: timerState.isActive
                  ? const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 20)
                  : null,
            ),

            // Item: Adicionar à Playlist
            _buildMenuItem(
              context,
              icon: Icons.playlist_add_rounded,
              title: 'Adicionar à Playlist',
              subtitle: 'Salvar no Firebase',
              onTap: () {
                Navigator.pop(context);
                if (currentSong != null) {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddToPlaylistSheet(song: currentSong),
                  );
                }
              },
            ),

            // Item: Equalizador
            _buildMenuItem(
              context,
              icon: Icons.equalizer_rounded,
              title: 'Equalizador',
              subtitle: 'Presets de áudio',
              onTap: () => _showEqualizerPresets(context),
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
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        title,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12))
          : null,
      trailing:
          trailing ?? const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  void _showTimerOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Parar música em...',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [15, 30, 45, 60]
                  .map((mins) => ChoiceChip(
                        label: Text('$mins min'),
                        selected: false,
                        onSelected: (_) {
                          ref.read(sleepTimerProvider.notifier).setTimer(mins);
                          Navigator.pop(context); // Fecha diálogo
                          Navigator.pop(context); // Fecha menu
                        },
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        labelStyle: const TextStyle(color: Colors.white),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ref.read(sleepTimerProvider.notifier).cancelTimer();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Desativar Timer',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEqualizerPresets(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Presets do Equalizador',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: ['Normal', 'Bass Boost', 'Vocal', 'Pop']
                  .map((preset) => OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(preset,
                            style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
