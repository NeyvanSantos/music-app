import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/theme/app_theme.dart';
import 'package:music_app/core/routes/app_router.dart';
import 'package:music_app/core/widgets/update_prompt_overlay.dart';

/// Widget raiz da aplicação.
///
/// Configura o tema global, rotas e providers de nível superior.
class MusicApp extends ConsumerWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Somax',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        // UpdatePromptOverlay engloba todo o app e bloqueia a UI se obrigatório
        return UpdatePromptOverlay(child: child);
      },
    );
  }
}
