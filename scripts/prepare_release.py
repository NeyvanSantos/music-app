import argparse
import hashlib
import re
import subprocess
from pathlib import Path

PUBSPEC_PATH = Path('pubspec.yaml')
ANDROID_LOCAL_PROPERTIES = Path('android/local.properties')
APK_PATH = Path('build/app/outputs/flutter-apk/app-release.apk')
RELEASE_OUTPUT_DIR = Path('build/release_metadata')


def increment_version(version_str):
    match = re.match(r'(\d+)\.(\d+)\.(\d+)\+(\d+)', version_str)
    if not match:
        return version_str

    major, minor, patch, build = map(int, match.groups())
    return f"{major}.{minor}.{patch + 1}+{build + 1}"


def read_current_version():
    if not PUBSPEC_PATH.exists():
        raise FileNotFoundError('Arquivo pubspec.yaml não encontrado!')

    content = PUBSPEC_PATH.read_text(encoding='utf-8')
    match = re.search(r'version:\s*([^\s]+)', content)
    if not match:
        raise ValueError('Versão não encontrada no pubspec.yaml')

    return match.group(1)


def update_pubspec(new_version):
    lines = PUBSPEC_PATH.read_text(encoding='utf-8').splitlines()
    updated_lines = []

    for line in lines:
        if line.startswith('version:'):
            updated_lines.append(f'version: {new_version}')
        else:
            updated_lines.append(line)

    PUBSPEC_PATH.write_text('\n'.join(updated_lines) + '\n', encoding='utf-8')


def get_flutter_command():
    if ANDROID_LOCAL_PROPERTIES.exists():
        properties = ANDROID_LOCAL_PROPERTIES.read_text(encoding='utf-8').splitlines()
        for line in properties:
            if line.startswith('flutter.sdk='):
                flutter_sdk = line.split('=', 1)[1].replace('\\\\', '\\').strip()
                flutter_bat = Path(flutter_sdk) / 'bin' / 'flutter.bat'
                if flutter_bat.exists():
                    return [str(flutter_bat)]

    return ['flutter']


def run_build():
    flutter_command = get_flutter_command()
    command = [*flutter_command, 'build', 'apk', '--release']

    print('\n[INFO] Iniciando build do Flutter (release apk)...')
    print(f'[INFO] Comando: {" ".join(command)}')

    try:
        subprocess.run(command, check=True)
        print('\n[SUCCESS] Build concluído com sucesso!')
        return True
    except subprocess.CalledProcessError as error:
        print(f'\n[ERROR] Erro durante o build: {error}')
        return False


def calculate_sha256(file_path):
    sha256 = hashlib.sha256()
    with file_path.open('rb') as apk_file:
        for chunk in iter(lambda: apk_file.read(1024 * 1024), b''):
            sha256.update(chunk)
    return sha256.hexdigest().upper()


def build_release_sql(version, apk_sha256, channel, update_url):
    return f"""UPDATE app_version_config
SET latest_version = '{version}',
    update_url = '{update_url}',
    apk_sha256 = '{apk_sha256}',
    whats_new = '["Nova funcionalidade de Playlist", "Melhorias de performance", "Correções de estabilidade"]',
    channel = '{channel}',
    updated_at = NOW()
WHERE channel = '{channel}';"""


def save_release_outputs(version, apk_sha256, sql, channel, update_url):
    RELEASE_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    slug = version.replace('+', '_')
    sql_path = RELEASE_OUTPUT_DIR / f'release_{channel}_{slug}.sql'
    latest_sql_path = RELEASE_OUTPUT_DIR / f'latest_{channel}_release.sql'
    summary_path = RELEASE_OUTPUT_DIR / f'release_{channel}_{slug}.txt'

    sql_path.write_text(sql + '\n', encoding='utf-8')
    latest_sql_path.write_text(sql + '\n', encoding='utf-8')
    summary_path.write_text(
        '\n'.join([
            f'version={version}',
            f'channel={channel}',
            f'apk_path={APK_PATH.resolve()}',
            f'public_apk={update_url}',
            f'apk_sha256={apk_sha256}',
            f'sql_path={sql_path.resolve()}',
        ]) + '\n',
        encoding='utf-8',
    )

    return sql_path, latest_sql_path, summary_path


def print_release_summary(version, apk_sha256, sql, sql_path, latest_sql_path, channel, update_url):
    print('\n' + '=' * 60)
    print('RELEASE PREPARADO')
    print('=' * 60)
    print(f'Versão: {version}')
    print(f'Canal: {channel}')
    print(f'APK: {APK_PATH.resolve()}')
    print(f'Publicação: {update_url}')
    print(f'SHA-256: {apk_sha256}')
    print(f'SQL salvo em: {sql_path.resolve()}')
    print(f'Último SQL salvo em: {latest_sql_path.resolve()}')
    print('=' * 60)
    print('COMANDO SQL PARA O SUPABASE')
    print('=' * 60)
    print(sql)
    print('=' * 60)
    print('\nDICA: use o canal preview para testar em aparelho real antes de promover a mesma versão para stable.')


def parse_args():
    parser = argparse.ArgumentParser(description='Prepara release Android com hash e SQL do OTA.')
    parser.add_argument('--dry-run', action='store_true', help='Mostra a próxima versão sem alterar arquivos.')
    parser.add_argument('--skip-build', action='store_true', help='Usa o APK já existente para gerar hash e SQL.')
    parser.add_argument('--channel', choices=['stable', 'preview'], default='stable', help='Canal do release OTA.')
    return parser.parse_args()


def main():
    args = parse_args()
    update_file_name = 'somax-preview.apk' if args.channel == 'preview' else 'somax.apk'
    update_url = f'https://somax-app.surge.sh/{update_file_name}'

    try:
        current_version = read_current_version()
    except (FileNotFoundError, ValueError) as error:
        print(f'[ERROR] {error}')
        return

    new_version = increment_version(current_version)
    print(f'[CURRENT] Versão atual detectada: {current_version}')
    print(f'[NEXT] Nova versão preparada: {new_version}')
    print(f'[CHANNEL] Canal selecionado: {args.channel}')

    if args.dry_run:
        print('\n[DRY-RUN] Simulação concluída. O pubspec.yaml NÃO foi alterado e o build NÃO foi iniciado.')
        return

    update_pubspec(new_version)
    print('[OK] pubspec.yaml atualizado!')

    if not args.skip_build:
        if not run_build():
            update_pubspec(current_version)
            print('[ROLLBACK] pubspec.yaml restaurado para a versão anterior após falha no build.')
            return
    elif not APK_PATH.exists():
        print(f'[ERROR] APK não encontrado em {APK_PATH}. Remova --skip-build ou gere o APK antes.')
        return

    if not APK_PATH.exists():
        print(f'[ERROR] APK não encontrado em {APK_PATH} após o build.')
        return

    apk_sha256 = calculate_sha256(APK_PATH)
    sql = build_release_sql(new_version, apk_sha256, args.channel, update_url)
    sql_path, latest_sql_path, _ = save_release_outputs(
        new_version,
        apk_sha256,
        sql,
        args.channel,
        update_url,
    )
    print_release_summary(
        new_version,
        apk_sha256,
        sql,
        sql_path,
        latest_sql_path,
        args.channel,
        update_url,
    )


if __name__ == '__main__':
    main()
