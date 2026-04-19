import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:music_app/features/player/presentation/providers/player_provider.dart';
import 'package:music_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:music_app/core/theme/app_colors.dart';

final playerBackgroundProvider = FutureProvider<Color>((ref) async {
  final settings = ref.watch(settingsProvider);
  if (!settings.dynamicBackground) return AppColors.primary;

  final song = ref.watch(playerProvider.select((s) => s.currentSong));
  
  if (song == null || song.thumbnailUrl == null) return AppColors.primary;

  try {
    final imageProvider = NetworkImage(song.thumbnailUrl!);
    final palette = await PaletteGenerator.fromImageProvider(imageProvider);
    return palette.vibrantColor?.color ?? palette.dominantColor?.color ?? AppColors.primary;
  } catch (e) {
    return AppColors.primary;
  }
});
