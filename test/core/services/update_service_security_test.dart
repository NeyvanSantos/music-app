import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/core/models/app_version_config.dart';
import 'package:music_app/core/services/update_service.dart';

void main() {
  group('UpdateService security helpers', () {
    test('accepts valid SHA-256 checksum', () {
      expect(
        UpdateService.isValidSha256(
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        ),
        isTrue,
      );
    });

    test('rejects invalid SHA-256 checksum', () {
      expect(UpdateService.isValidSha256('abc123'), isFalse);
      expect(UpdateService.isValidSha256(null), isFalse);
    });

    test('accepts trusted HTTPS update URL', () {
      final uri = UpdateService.parseTrustedUpdateUri(
        'https://www.dropbox.com/scl/fi/file/app-release.apk?dl=0',
      );

      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'www.dropbox.com');
    });

    test('rejects untrusted or insecure update URL', () {
      expect(
        UpdateService.parseTrustedUpdateUri('http://www.dropbox.com/file.apk'),
        isNull,
      );
      expect(
        UpdateService.parseTrustedUpdateUri(
            'https://evil.example.com/file.apk'),
        isNull,
      );
    });

    test('builds direct Dropbox download URL with cache buster', () {
      final url = UpdateService.buildDownloadUrl(
        'https://www.dropbox.com/scl/fi/file/app-release.apk?rlkey=abc&dl=0',
        cacheBuster: 12345,
      );

      expect(url, contains('dl=1'));
      expect(url, contains('t=12345'));
      expect(url, contains('rlkey=abc'));
    });

    test('secure config requires trusted URL and checksum', () {
      const secureConfig = AppVersionConfig(
        channel: 'stable',
        latestVersion: '2.3.10+20',
        updateUrl: 'https://www.dropbox.com/scl/fi/file/app-release.apk?dl=1',
        apkSha256:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        isMandatory: true,
        whatsNew: ['Security hardening'],
      );

      const insecureConfig = AppVersionConfig(
        channel: 'stable',
        latestVersion: '2.3.10+20',
        updateUrl: 'https://evil.example.com/app-release.apk',
        apkSha256: null,
        isMandatory: true,
        whatsNew: ['Security hardening'],
      );

      expect(UpdateService.isSecureUpdateConfig(secureConfig), isTrue);
      expect(UpdateService.isSecureUpdateConfig(insecureConfig), isFalse);
    });

    test('selects matching preview channel when available', () {
      final config = UpdateService.selectVersionConfig(
        [
          {
            'id': 1,
            'channel': 'stable',
            'latest_version': '2.3.14+24',
            'update_url': 'https://somax-app.surge.sh/somax.apk',
            'apk_sha256':
                '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
            'is_mandatory': true,
            'whats_new': ['Stable'],
          },
          {
            'id': 2,
            'channel': 'preview',
            'latest_version': '2.3.15+25',
            'update_url': 'https://somax-app.surge.sh/somax-preview.apk',
            'apk_sha256':
                'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210',
            'is_mandatory': false,
            'whats_new': ['Preview'],
          },
        ],
        channel: 'preview',
      );

      expect(config, isNotNull);
      expect(config!.channel, 'preview');
      expect(config.latestVersion, '2.3.15+25');
    });

    test('falls back to stable channel when preview is unavailable', () {
      final config = UpdateService.selectVersionConfig(
        [
          {
            'id': 1,
            'latest_version': '2.3.14+24',
            'update_url': 'https://somax-app.surge.sh/somax.apk',
            'apk_sha256':
                '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
            'is_mandatory': true,
            'whats_new': ['Stable'],
          },
        ],
        channel: 'preview',
      );

      expect(config, isNotNull);
      expect(config!.channel, 'stable');
    });
  });
}
