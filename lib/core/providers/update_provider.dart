import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/models/app_version_config.dart';
import 'package:music_app/core/services/update_service.dart';
import 'package:music_app/core/providers/shared_prefs_provider.dart';

/// Provider que fornece o AppVersionConfig lido do Firestore em tempo real.
final remoteVersionConfigProvider = StreamProvider<AppVersionConfig?>((ref) {
  return UpdateService.watchVersionConfig();
});

/// Provider que fornece a versão local do App.
final localVersionProvider = FutureProvider<String>((ref) async {
  return await UpdateService.getCurrentVersion();
});

/// Provider que combina remote e local para saber se devemos exibir o prompt.
final updateRequiredProvider = Provider<AppVersionConfig?>((ref) {
  final remote = ref.watch(remoteVersionConfigProvider).value;
  final local = ref.watch(localVersionProvider).value;

  if (remote == null || local == null) {
    return null;
  }

  final hasUpdate = UpdateService.hasUpdate(remote.latestVersion, local);

  if (hasUpdate && remote.isMandatory) {
    debugPrint('SOMX_UPDATE: Bloqueio Ativado para v${remote.latestVersion}');
    return remote;
  }
  return null;
});

/// Provider que gerencia se o usuário já viu as novidades da versão instalada.
final whatsNewVisibilityProvider =
    NotifierProvider<WhatsNewVisibilityNotifier, String?>(() {
  return WhatsNewVisibilityNotifier();
});

class WhatsNewVisibilityNotifier extends Notifier<String?> {
  static const _key = 'last_seen_whats_new_version';

  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_key);
  }

  Future<void> markAsSeen(String version) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, version);
    state = version;
  }
}

/// Provider que decide se devemos mostrar as novidades AGORA.
final showWhatsNewProvider = Provider<AppVersionConfig?>((ref) {
  final remote = ref.watch(remoteVersionConfigProvider).value;
  final local = ref.watch(localVersionProvider).value;
  final seenVersion = ref.watch(whatsNewVisibilityProvider);
  final hasUpdateRequired = ref.watch(updateRequiredProvider) != null;

  if (remote == null || local == null || hasUpdateRequired) return null;

  // Só mostramos se o app estiver atualizado (local >= remote) e ele ainda não viu as notícias desta versão
  final isUpToDate = !UpdateService.hasUpdate(remote.latestVersion, local);

  if (isUpToDate && seenVersion != local && remote.whatsNew.isNotEmpty) {
    return remote;
  }

  return null;
});
