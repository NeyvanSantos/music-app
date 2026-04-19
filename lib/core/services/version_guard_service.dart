import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço responsável por detectar mudanças de versão e realizar limpezas
/// de cache para evitar que estados da versão anterior causem erros/loops.
class VersionGuardService {
  static const String _lastVersionKey = 'somax_last_installed_version';

  /// Verifica se houve mudança de versão e executa limpeza profunda se necessário.
  /// Retorna [true] se uma limpeza foi realizada.
  static Future<bool> performDeepCleanIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packageInfo = await PackageInfo.fromPlatform();

      final currentVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';
      final lastVersion = prefs.getString(_lastVersionKey);

      debugPrint(
          'SOMX_GUARD: Versão Atual: $currentVersion | Última conhecida: $lastVersion');

      if (lastVersion == null) {
        // Primeira instalação, apenas salva a versão
        await prefs.setString(_lastVersionKey, currentVersion);
        return false;
      }

      if (lastVersion != currentVersion) {
        debugPrint(
            'SOMX_GUARD: 🚨 Mudança de versão detectada! Iniciando Deep Clean...');

        // 1. Limpa Cache do Firestore (Obrigatório para matar o loop de versão)
        // Isso força o app a ler o Firebase do zero, ignorando caches offline velhos.
        try {
          await FirebaseFirestore.instance.terminate();
          await FirebaseFirestore.instance.clearPersistence();
          debugPrint('SOMX_GUARD: ✅ Cache do Firestore limpo.');
        } catch (e) {
          debugPrint('SOMX_GUARD: ⚠️ Erro ao limpar Firestore: $e');
        }

        // 2. Limpeza de estados de busca ou temporários se necessário
        // (Adicione outras limpezas aqui no futuro)

        // 3. Atualiza a versão salva para a nova
        await prefs.setString(_lastVersionKey, currentVersion);

        debugPrint('SOMX_GUARD: ✨ Deep Clean concluído com sucesso.');
        return true;
      }

      debugPrint(
          'SOMX_GUARD: App está atualizado. Nenhuma limpeza necessária.');
      return false;
    } catch (e) {
      debugPrint('SOMX_GUARD: [ERRO] Falha no processo de guarda: $e');
      return false;
    }
  }
}
