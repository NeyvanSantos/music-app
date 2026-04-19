# Download Proxy MVP

Backend minimo para tirar o trabalho de download do app e concentrar em um servidor proprio.

## O que ele faz

- `POST /downloads` cria um job para uma musica do YouTube.
- `GET /downloads/:jobId` retorna status do job.
- `GET /files/:fileName` baixa o arquivo MP3 pronto.
- Reaproveita downloads ja processados pelo mesmo `youtubeId`.

## Como funciona

1. O app envia os dados da musica e o `youtubeId`.
2. O backend enfileira o job em memoria.
3. O worker executa `yt-dlp` e usa `ffmpeg` para gerar MP3.
4. O backend guarda um indice simples em `storage/cache-index.json`.
5. O arquivo final fica em `storage/files`.
6. O app faz polling ate receber `completed` e baixa o arquivo.

## Requisitos

- Node 18+
- `yt-dlp` disponivel no PATH ou via `python -m yt_dlp`
- `ffmpeg` disponivel no PATH

## Subir localmente

1. Copie `.env.example` para `.env`.
2. Ajuste `BASE_URL`, `YT_DLP_BIN`, `YT_DLP_ARGS` e `FFMPEG_BIN` se necessario.
3. Rode `node server.js`.

## Exemplo de request

```bash
curl -X POST http://localhost:8080/downloads ^
  -H "Content-Type: application/json" ^
  -d "{\"song\":{\"id\":\"kI6ywewtYkc\",\"youtubeId\":\"kI6ywewtYkc\",\"title\":\"Teste\",\"artist\":\"Artista\"}}"
```

## Integracao com o app

Passe a URL do backend no build do Flutter:

```bash
flutter run --dart-define=SOMAX_DOWNLOAD_PROXY_URL=http://10.0.2.2:8080
```

No APK release:

```bash
flutter build apk --release --dart-define=SOMAX_DOWNLOAD_PROXY_URL=https://seu-backend.com
```

## Deploy no Railway

### Arquivos

- Use o `Dockerfile` desta pasta.
- Monte um volume persistente em `/data`.

### Variaveis minimas

```env
PORT=8080
HOST=0.0.0.0
BASE_URL=https://seu-servico.up.railway.app
STORAGE_DIR=/data
YT_DLP_BIN=python3
YT_DLP_ARGS=-m yt_dlp
FFMPEG_BIN=ffmpeg
MAX_JOB_AGE_MINUTES=60
```

### Healthcheck

- Endpoint: `/health`

### Depois do deploy

1. Abra `https://seu-servico.up.railway.app/health`.
2. Confirme resposta `{"ok":true,...}`.
3. Gere o APK Android com:

```bash
flutter build apk --release --dart-define=SOMAX_DOWNLOAD_PROXY_URL=https://seu-servico.up.railway.app
```

## Limites do MVP

- Jobs ficam em memoria.
- O cache em disco e simples, sem expiracao por tamanho.
- Nao ha autenticacao.
- Nao ha fila distribuida nem storage externo.
- Se o servidor reiniciar, os jobs em andamento sao perdidos.

Para producao, o minimo razoavel e trocar:

- memoria por fila persistente;
- `storage/` local por bucket;
- endpoint aberto por autenticacao/rate limit;
- um unico processo por worker controlado.

## Configuracao no Windows com Python

Se `yt-dlp --version` nao funcionar, mas `python -m yt_dlp --version` funcionar, use no `.env`:

```env
YT_DLP_BIN=python
YT_DLP_ARGS=-m yt_dlp
```
