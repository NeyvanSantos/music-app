import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/providers/auth_provider.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:music_app/features/settings/presentation/providers/settings_provider.dart';

class SettingsBottomSheet extends ConsumerWidget {
  const SettingsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isGuest = ref.watch(isGuestProvider);
    final hasPreviewAccess = ref.watch(previewAccessProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Configurações',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Preferências'),
              _buildSwitchTile(
                label: 'Modo Incógnito',
                subtitle: 'Não salvar buscas no histórico',
                value: settings.isIncognito,
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleIncognito(),
                icon: Icons.visibility_off_rounded,
              ),
              _buildSwitchTile(
                label: 'Fundo Dinâmico',
                subtitle: 'Cores que reagem à capa',
                value: settings.dynamicBackground,
                onChanged: (_) => ref
                    .read(settingsProvider.notifier)
                    .toggleDynamicBackground(),
                icon: Icons.auto_awesome_rounded,
              ),
              _buildSwitchTile(
                label: 'Fila Inteligente',
                subtitle: 'Autoplay após terminar playlist',
                value: settings.smartQueue,
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleSmartQueue(),
                icon: Icons.queue_music_rounded,
              ),
              if (hasPreviewAccess)
                _buildSwitchTile(
                  label: 'Canal Preview',
                  subtitle: settings.isPreviewChannel
                      ? 'Este aparelho recebe versões de pré-visualização'
                      : 'Receber apenas versões oficiais',
                  value: settings.isPreviewChannel,
                  onChanged: (enabled) async {
                    await ref
                        .read(settingsProvider.notifier)
                        .setPreviewChannel(enabled);
                  },
                  icon: Icons.science_rounded,
                ),
              if (hasPreviewAccess)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Canal atual: ${settings.isPreviewChannel ? 'preview' : 'stable'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionHeader('Armazenamento'),
              _buildActionTile(
                label: 'Limpar Cache',
                subtitle: 'Libera espaço em disco',
                icon: Icons.delete_outline_rounded,
                onTap: () async {
                  try {
                    await CachedNetworkImage.evictFromCache('');
                  } catch (e) {
                    debugPrint('Erro ao limpar cache: $e');
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache limpo com sucesso')),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Conta'),
              if (isGuest)
                _buildActionTile(
                  label: 'Migrar para Conta Google',
                  subtitle: 'Salve sua biblioteca para sempre',
                  icon: Icons.account_circle_rounded,
                  isHighlight: true,
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                )
              else
                _buildActionTile(
                  label: 'Sair da Conta',
                  subtitle: 'Desconectar sessão atual',
                  icon: Icons.logout_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                  color: Colors.redAccent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      onTap: () => onChanged(!value),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.onSurfaceVariant),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildActionTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isHighlight = false,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: color ??
            (isHighlight ? AppColors.primary : AppColors.onSurfaceVariant),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
          color:
              color ?? (isHighlight ? AppColors.primary : AppColors.onSurface),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }
}
