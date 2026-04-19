import 'package:equatable/equatable.dart';

/// Modelo de configuração de versão do Firebase.
class AppVersionConfig extends Equatable {
  final String channel;
  final String latestVersion;
  final String updateUrl;
  final String? apkSha256;
  final bool isMandatory;
  final List<String> whatsNew;

  const AppVersionConfig({
    required this.channel,
    required this.latestVersion,
    required this.updateUrl,
    this.apkSha256,
    required this.isMandatory,
    required this.whatsNew,
  });

  factory AppVersionConfig.fromMap(Map<String, dynamic> map) {
    final rawChannel = (map['channel'] as String? ?? 'stable').trim();

    return AppVersionConfig(
      channel: rawChannel.isEmpty ? 'stable' : rawChannel.toLowerCase(),
      latestVersion: map['latest_version'] as String? ?? '1.0.0',
      updateUrl: map['update_url'] as String? ?? '',
      apkSha256: map['apk_sha256'] as String?,
      isMandatory: map['is_mandatory'] as bool? ?? true,
      whatsNew: List<String>.from(map['whats_new'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
        channel,
        latestVersion,
        updateUrl,
        apkSha256,
        isMandatory,
        whatsNew,
      ];
}
