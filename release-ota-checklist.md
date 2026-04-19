# Release OTA Checklist

## Antes do build

- Confirmar que `pubspec.yaml` está com a versão correta ou rodar `python scripts/prepare_release.py`
- Confirmar que `firestore.rules` e o RLS do Supabase já estão publicados
- Garantir que o link final do APK será HTTPS e com `dl=1`

## Durante o release

- Gerar o APK release
- Gerar o `SHA-256` do APK
- Conferir se o SQL do release contém `latest_version`, `update_url` e `apk_sha256`
- Salvar o SQL em `build/release_metadata/latest_release.sql`

## Publicação

- Subir o APK para o destino final
- Validar que o link abre o download direto do APK
- Executar o `UPDATE app_version_config` no Supabase com o hash do APK publicado

## Verificação manual em aparelho real

- Instalar a versão anterior do app
- Abrir o app e confirmar que o overlay de update aparece
- Executar o download OTA
- Confirmar que a instalação inicia sem erro de checksum
- Abrir a nova versão e confirmar que o overlay não entra em loop
- Validar ao menos login, busca, player e biblioteca

## Depois do release

- Arquivar ou copiar o hash usado no release
- Guardar o SQL final aplicado
- Registrar qualquer falha observada no processo antes do próximo release
