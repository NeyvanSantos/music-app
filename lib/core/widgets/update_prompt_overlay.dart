import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/core/providers/update_provider.dart';
import 'package:music_app/core/services/update_service.dart';
import 'package:music_app/core/theme/app_colors.dart';
import 'package:ota_update/ota_update.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Um widget overlay envolvente que bloqueia o uso do app se uma atualização
/// obrigatória estiver disponível.
class UpdatePromptOverlay extends ConsumerWidget {
  final Widget child;

  const UpdatePromptOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateConfig = ref.watch(updateRequiredProvider);

    // Log para diagnosticar se o widget está lendo o estado de atualização
    if (updateConfig != null) {
      debugPrint(
          'SOMX_UPDATE: Overlay UI acionada para v${updateConfig.latestVersion}');
    }

    return Stack(
      children: [
        child,
        if (updateConfig != null)
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: _BlockingUpdateScreen(
                updateUrl: updateConfig.updateUrl,
                latestVersion: updateConfig.latestVersion,
                whatsNew: updateConfig.whatsNew,
              ),
            ),
          ),
      ],
    );
  }
}

class _BlockingUpdateScreen extends StatefulWidget {
  final String updateUrl;
  final String latestVersion;
  final List<String> whatsNew;

  const _BlockingUpdateScreen({
    required this.updateUrl,
    required this.latestVersion,
    required this.whatsNew,
  });

  @override
  State<_BlockingUpdateScreen> createState() => _BlockingUpdateScreenState();
}

class _BlockingUpdateScreenState extends State<_BlockingUpdateScreen> {
  double _progress = 0;
  bool _isDownloading = false;
  String? _errorMessage;
  StreamSubscription? _subscription;
  OtaEvent? _currentEvent;
  String? _localVersion;

  @override
  void initState() {
    super.initState();
    _loadLocalVersion();
  }

  Future<void> _loadLocalVersion() async {
    final version = await UpdateService.getCurrentVersion();
    if (mounted) setState(() => _localVersion = version);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _launchBrowser() async {
    final url = Uri.parse(widget.updateUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('SOMX_OTA: Não foi possível abrir $url no navegador.');
    }
  }

  Future<void> _startUpdate() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _progress = 0;
      _errorMessage = null;
    });

    try {
      String finalUrl = widget.updateUrl;
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;

      // Inteligência de Link: Corrige links do Dropbox para download direto
      if (finalUrl.contains('dropbox.com')) {
        finalUrl = finalUrl.replaceAll('?dl=0', '').replaceAll('&dl=0', '');
        finalUrl = finalUrl.contains('?') ? '$finalUrl&dl=1' : '$finalUrl?dl=1';
      }
      // Limpeza de versões antigas baixadas para evitar conflitos
      try {
        final tempDir = await getApplicationDocumentsDirectory();
        final otaDir = Directory('${tempDir.parent.path}/files/ota_update');
        if (await otaDir.exists()) {
          debugPrint('SOMX_OTA: Limpando pasta de atualizações antigas...');
          await otaDir.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('SOMX_OTA: Aviso ao limpar pasta (pode ser ignorado): $e');
      }

      // Adiciona Cache Buster para evitar download de APK antigo guardado em cache
      finalUrl = finalUrl.contains('?')
          ? '$finalUrl&t=$cacheBuster'
          : '$finalUrl?t=$cacheBuster';

      debugPrint('SOMX_OTA: Iniciando execução com URL: $finalUrl');
      _subscription = OtaUpdate()
          .execute(
        finalUrl,
      )
          .listen(
        (OtaEvent event) {
          debugPrint(
              'SOMX_OTA: Evento recebido: ${event.status} - ${event.value}%');
          setState(() {
            _currentEvent = event;
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                _progress = double.tryParse(event.value ?? '0') ?? 0;
                break;
              case OtaStatus.INSTALLING:
                debugPrint('SOMX_OTA: Iniciando instalação nativa...');
                _isDownloading = false;
                _progress = 100;
                break;
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                debugPrint(
                    'SOMX_OTA: Permissão de instalação negada pelo usuário.');
                _isDownloading = false;
                _errorMessage = 'Permissão negada para instalar.';
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                debugPrint(
                    'SOMX_OTA: Já existe um download em execução. Ignorando.');
                break;
              case OtaStatus.CHECKSUM_ERROR:
                debugPrint('SOMX_OTA: Erro de Checksum. APK corrompido.');
                _isDownloading = false;
                _errorMessage = 'Arquivo baixado está corrompido.';
                break;
              case OtaStatus.DOWNLOAD_ERROR:
                debugPrint('SOMX_OTA: Erro de Download. Verifique a conexão.');
                _isDownloading = false;
                _errorMessage = 'Erro ao baixar. Verifique sua internet.';
                break;
              case OtaStatus.INTERNAL_ERROR:
              case OtaStatus.INSTALLATION_ERROR:
                debugPrint('SOMX_OTA: ERRO FATAL: ${event.status}');
                _isDownloading = false;
                _errorMessage = 'Erro interno: ${event.status}';
                break;
              default:
                break;
            }
          });
        },
        onError: (e) {
          debugPrint('SOMX_OTA: Erro capturado no stream: $e');
          setState(() {
            _isDownloading = false;
            _errorMessage = 'Falha na conexão.';
          });
        },
      );
    } catch (e) {
      debugPrint('SOMX_OTA: Exceção ao executar ota_update: $e');
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Não foi possível iniciar o download.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo sólido (mais leve para emuladores)
          Container(
            color: Colors.black.withOpacity(0.95),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with pulse effect if downloading
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: _isDownloading ? 1.2 : 1.0),
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      onEnd: () => setState(() {}), // Trigger rebuild for loop
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isDownloading
                              ? Icons.cloud_download_rounded
                              : Icons.system_update_rounded,
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      _isDownloading
                          ? 'Baixando Atualização'
                          : 'Nova Atualização!',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    Text(
                      _isDownloading
                          ? 'Aguarde enquanto preparamos a versão v${widget.latestVersion} para você.'
                          : 'Temos novidades incríveis na versão v${widget.latestVersion}.\nPara continuar curtindo o Somax, instale agora.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Debug Versions Info
                    if (!_isDownloading && _localVersion != null) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onLongPress: () {
                          // Botão secreto de bypass em caso de loop infinito
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'DEBUG: $_localVersion ➔ ${widget.latestVersion} (Segure para ignorar)',
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Lista de Novidades (whats_new)
                    if (!_isDownloading && widget.whatsNew.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'O que há de novo:',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: widget.whatsNew
                                .map((item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 6),
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withOpacity(0.5),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              item,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Action Button or Loading
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isDownloading ? null : _startUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor:
                              AppColors.surfaceContainerHigh,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Text(
                          _isDownloading ? 'BAIXANDO...' : 'ATUALIZAR AGORA',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // Neon Progress Bar below button
                    if (_isDownloading || _progress > 0) ...[
                      const SizedBox(height: 24),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 6,
                            width: (MediaQuery.of(context).size.width - 128) *
                                (_progress / 100),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_progress.toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _startUpdate,
                        child: const Text('Tentar novamente',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
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
