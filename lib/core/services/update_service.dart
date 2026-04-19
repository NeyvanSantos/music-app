import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:music_app/core/models/app_version_config.dart';
import 'package:music_app/core/services/supabase_service.dart';

/// Serviço que escuta configurações de versão do Supabase.
class UpdateService {
  UpdateService._();

  /// Stream para obter as configurações de versão em tempo real do Supabase.
  static Stream<AppVersionConfig?> watchVersionConfig() {
    debugPrint('SOMX_UPDATE: Iniciando Stream do Supabase...');
    try {
      return SupabaseService.client
          .from('app_version_config')
          .stream(primaryKey: ['id'])
          .limit(1)
          .map((data) {
            debugPrint('SOMX_UPDATE: Evento recebido da Stream. Dados: $data');
            if (data.isEmpty) {
              debugPrint(
                  'SOMX_UPDATE: Nenhum dado encontrado na tabela app_version_config.');
              return null;
            }
            final config = AppVersionConfig.fromMap(data.first);
            debugPrint(
                'SOMX_UPDATE: Config carregada: v${config.latestVersion}');
            return config;
          });
    } catch (e) {
      debugPrint('SOMX_UPDATE: Erro ao iniciar Stream: $e');
      return Stream.value(null);
    }
  }

  /// Pega a versão atual instalada do app
  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  /// Compara duas versões 'x.y.z+build'. Retorna verdadeiro se remote > local.
  static bool hasUpdate(String remoteStr, String localStr) {
    try {
      // Limpeza profunda de strings
      final remoteClean = remoteStr.trim();
      final localClean = localStr.trim();

      debugPrint(
          'SOMX_UPDATE: [DEBUG_STRINGS] Remota: "$remoteClean" | Local: "$localClean"');

      if (remoteClean == localClean) {
        debugPrint('SOMX_UPDATE: Versões são idênticas. Sem atualização.');
        return false;
      }

      // Extração de Base e Build
      final remoteParts = remoteClean.split('+');
      final localParts = localClean.split('+');

      final remoteBase = remoteParts[0].replaceAll(RegExp(r'[^0-9.]'), '');
      final localBase = localParts[0].replaceAll(RegExp(r'[^0-9.]'), '');

      final rSegments = remoteBase.split('.');
      final lSegments = localBase.split('.');

      // Compara X.Y.Z (Major.Minor.Patch)
      final maxLength = rSegments.length > lSegments.length
          ? rSegments.length
          : lSegments.length;
      for (int i = 0; i < maxLength; i++) {
        final r = i < rSegments.length ? int.tryParse(rSegments[i]) ?? 0 : 0;
        final l = i < lSegments.length ? int.tryParse(lSegments[i]) ?? 0 : 0;

        if (r > l) {
          debugPrint('SOMX_UPDATE: Update detectado na base X.Y.Z ($r > $l)');
          return true;
        }
        if (r < l) {
          debugPrint(
              'SOMX_UPDATE: Versão local é superior na base X.Y.Z ($l > $r)');
          return false;
        }
      }

      // Se a base X.Y.Z for idêntica, comparamos o Build Number (+X)
      // Se a remota tiver build e a local não, assume remota > local
      if (remoteParts.length > 1 && localParts.length == 1) {
        debugPrint(
            'SOMX_UPDATE: Remota tem build number e local não. Update sugerido.');
        return true;
      }

      // Se ambas tiverem build number, compara logicamente
      if (remoteParts.length > 1 && localParts.length > 1) {
        final rBuild =
            int.tryParse(remoteParts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final lBuild =
            int.tryParse(localParts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        if (rBuild > lBuild) {
          debugPrint(
              'SOMX_UPDATE: Update detectado no Build Number ($rBuild > $lBuild)');
          return true;
        }
      }

      debugPrint('SOMX_UPDATE: Sem atualização necessária.');
      return false;
    } catch (e) {
      debugPrint('SOMX_UPDATE: [ERRO FATAL] Falha ao comparar: $e');
      return false;
    }
  }
}
