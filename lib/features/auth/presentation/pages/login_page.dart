import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/providers/auth_provider.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:music_app/core/theme/app_theme.dart';
import 'package:music_app/core/theme/app_typography.dart';

/// Tela de Login — Autenticação.
///
/// Permite ao usuário entrar utilizando Google Sign-In.
/// O estado é gerenciado pelo Riverpod através do [authControllerProvider].
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta erros de autenticação para exibir um SnackBar
    ref.listen<AsyncValue<void>>(
      authControllerProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, stack) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  error.toString().contains('serverClientId')
                      ? 'Nenhuma ID configurada no Firebase para Google Sign-In. Use "Entrar como Convidado" por baixo.'
                      : error.toString(),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );
      },
    );

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // ─── Logo / Branding ─────────────────────────
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    child: Image.asset(
                      'assets/images/somax_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXxl),

              // ─── Title ───────────────────────────────────
              Center(
                child: Text(
                  'Somax',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: 6,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Center(
                child: Text(
                  'SINTONIZE SUA FREQUÊNCIA',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 4,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ─── Google Login Button ─────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.g_mobiledata_rounded, size: 32),
                            const SizedBox(width: 8),
                            Text(
                              'ENTRAR COM GOOGLE',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ─── Guest Access (Simplified Link) ──────────
              Center(
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(authControllerProvider.notifier)
                          .enterAsGuest(),
                  style: ButtonStyle(
                    foregroundColor: WidgetStateColor.resolveWith((states) => AppColors.primary),
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    textStyle: WidgetStateProperty.resolveWith((states) {
                      final style = AppTypography.titleMedium;
                      if (states.contains(WidgetState.pressed)) {
                        return style.copyWith(decoration: TextDecoration.underline);
                      }
                      return style.copyWith(decoration: TextDecoration.none);
                    }),
                  ),
                  child: const Text('Entrar como Convidado'),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
