'use strict';

const fs = require('node:fs');
const fsp = require('node:fs/promises');
const http = require('node:http');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawn } = require('node:child_process');
const { URL } = require('node:url');

loadEnv(path.join(__dirname, '.env'));

const PORT = Number(process.env.PORT || 8080);
const HOST = process.env.HOST || '0.0.0.0';
const BASE_URL = (process.env.BASE_URL || `http://localhost:${PORT}`).replace(/\/+$/, '');
const STORAGE_DIR = path.resolve(__dirname, process.env.STORAGE_DIR || './storage');
const FILES_DIR = path.join(STORAGE_DIR, 'files');
const WORK_DIR = path.join(STORAGE_DIR, 'work');
const CACHE_INDEX_PATH = path.join(STORAGE_DIR, 'cache-index.json');
const RUNTIME_DIR = path.join(STORAGE_DIR, 'runtime');
const YT_DLP_BIN = process.env.YT_DLP_BIN || 'yt-dlp';
const YT_DLP_ARGS = splitCommandArgs(process.env.YT_DLP_ARGS || '');
const YT_DLP_USER_AGENT =
  process.env.YT_DLP_USER_AGENT ||
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36';
const YOUTUBE_COOKIES = process.env.YOUTUBE_COOKIES || '';
const YOUTUBE_COOKIES_B64 = process.env.YOUTUBE_COOKIES_B64 || '';
const YOUTUBE_COOKIES_PATH = process.env.YOUTUBE_COOKIES_PATH || '';
const YOUTUBE_COOKIES_PARTS = collectEnvParts('YOUTUBE_COOKIES_PART_');
const YOUTUBE_COOKIES_B64_PARTS = collectEnvParts('YOUTUBE_COOKIES_B64_PART_');
const FFMPEG_BIN = process.env.FFMPEG_BIN || 'ffmpeg';
const MAX_JOB_AGE_MINUTES = Number(process.env.MAX_JOB_AGE_MINUTES || 60);

const jobs = new Map();
const cacheIndex = new Map();
let activeJobCount = 0;
let ytDlpCookiesPath = '';

async function bootstrap() {
  await Promise.all([
    fsp.mkdir(FILES_DIR, { recursive: true }),
    fsp.mkdir(WORK_DIR, { recursive: true }),
    fsp.mkdir(RUNTIME_DIR, { recursive: true }),
  ]);
  ytDlpCookiesPath = await ensureCookiesFile();
  await loadCacheIndex();

  const server = http.createServer(async (req, res) => {
    try {
      await route(req, res);
    } catch (error) {
      if (error instanceof HttpError) {
        sendJson(res, error.statusCode, { error: error.message });
        return;
      }
      console.error('[download-proxy] unexpected error', error);
      sendJson(res, 500, { error: 'Erro interno no backend de download.' });
    }
  });

  server.listen(PORT, HOST, () => {
    console.log(`[download-proxy] listening on ${HOST}:${PORT}`);
    console.log(
      `[download-proxy] config baseUrl=${BASE_URL} storageDir=${STORAGE_DIR} ytDlpBin=${YT_DLP_BIN} cookies=${ytDlpCookiesPath ? 'enabled' : 'disabled'}`,
    );
  });

  setInterval(cleanupExpiredJobs, 10 * 60 * 1000).unref();
}

async function route(req, res) {
  const method = req.method || 'GET';
  const requestUrl = new URL(req.url || '/', BASE_URL);
  const pathname = requestUrl.pathname;

  if (method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    });
    res.end();
    return;
  }

  if (method === 'POST' && pathname === '/downloads') {
    const body = await readJsonBody(req);
    return handleCreateDownload(body, res);
  }

  if (method === 'GET' && pathname.startsWith('/downloads/')) {
    const jobId = decodeURIComponent(pathname.slice('/downloads/'.length));
    return handleGetDownload(req, jobId, res);
  }

  if (method === 'GET' && pathname.startsWith('/files/')) {
    const fileName = decodeURIComponent(pathname.slice('/files/'.length));
    return handleGetFile(fileName, res);
  }

  if (method === 'GET' && pathname === '/health') {
    return sendJson(res, 200, {
      ok: true,
      activeJobs: activeJobCount,
      totalJobs: jobs.size,
      cookiesEnabled: Boolean(ytDlpCookiesPath),
    });
  }

  sendJson(res, 404, { error: 'Rota nao encontrada.' });
}

async function handleCreateDownload(body, res) {
  const song =
    body && typeof body === 'object' && body.song && typeof body.song === 'object'
      ? body.song
      : null;
  if (!song) {
    return sendJson(res, 400, { error: 'Payload deve conter song.' });
  }

  const youtubeId = song && typeof song.youtubeId === 'string' && song.youtubeId.trim()
    ? song.youtubeId.trim()
    : song && typeof song.id === 'string'
      ? song.id.trim()
      : '';

  if (!youtubeId) {
    return sendJson(res, 400, { error: 'youtubeId obrigatorio.' });
  }

  const activeJob = findReusableJob(youtubeId);
  if (activeJob) {
    logEvent('job-reused', {
      youtubeId,
      jobId: activeJob.id,
      status: activeJob.status,
    });
    return sendJson(res, 202, {
      jobId: activeJob.id,
      status: activeJob.status,
      cached: activeJob.status === 'completed',
    });
  }

  const cachedEntry = await getValidCacheEntry(youtubeId);
  if (cachedEntry) {
    const cachedJob = createJob({
      song,
      youtubeId,
      outputFileName: cachedEntry.outputFileName,
      status: 'completed',
      retainFile: true,
      error: null,
    });
    jobs.set(cachedJob.id, cachedJob);
    logEvent('cache-hit', {
      youtubeId,
      jobId: cachedJob.id,
      file: cachedEntry.outputFileName,
    });
    return sendJson(res, 202, {
      jobId: cachedJob.id,
      status: cachedJob.status,
      cached: true,
    });
  }

  const outputFileName = buildOutputFileName(song, youtubeId);
  logEvent('cache-miss', {
    youtubeId,
    file: outputFileName,
  });
  const job = createJob({
    song,
    youtubeId,
    outputFileName,
    status: 'queued',
    retainFile: true,
    error: null,
  });

  jobs.set(job.id, job);
  logEvent('job-created', {
    youtubeId,
    jobId: job.id,
    file: outputFileName,
  });
  processJob(job).catch((error) => {
    console.error('[download-proxy] job failed', error);
  });

  sendJson(res, 202, {
    jobId: job.id,
    status: job.status,
    cached: false,
  });
}

function handleGetDownload(req, jobId, res) {
  const job = jobs.get(jobId);
  if (!job) {
    return sendJson(res, 404, { error: 'Job nao encontrado.' });
  }

  const publicBaseUrl = resolvePublicBaseUrl(req);

  sendJson(res, 200, {
    jobId: job.id,
    status: job.status,
    createdAt: job.createdAt,
    updatedAt: job.updatedAt,
    error: job.error,
    contentType: job.contentType,
    downloadUrl:
      job.status === 'completed'
        ? `${publicBaseUrl}/files/${encodeURIComponent(job.outputFileName)}`
        : null,
  });
}

function createJob({
  song,
  youtubeId,
  outputFileName,
  status,
  retainFile,
  error,
}) {
  const jobId = crypto.randomUUID();
  return {
    id: jobId,
    status,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    youtubeId,
    song: {
      id: String(song.id || youtubeId),
      title: String(song.title || 'Faixa sem nome'),
      artist: String(song.artist || 'Artista desconhecido'),
      thumbnailUrl: song.thumbnailUrl ? String(song.thumbnailUrl) : null,
      youtubeId,
    },
    outputFileName,
    outputPath: path.join(FILES_DIR, outputFileName),
    error,
    contentType: 'audio/mpeg',
    retainFile,
  };
}

async function handleGetFile(fileName, res) {
  if (fileName.includes('/') || fileName.includes('\\')) {
    return sendJson(res, 400, { error: 'Nome de arquivo invalido.' });
  }

  const filePath = path.join(FILES_DIR, fileName);

  try {
    await fsp.access(filePath, fs.constants.R_OK);
  } catch {
    return sendJson(res, 404, { error: 'Arquivo nao encontrado.' });
  }

  const stream = fs.createReadStream(filePath);
  res.writeHead(200, {
    'Content-Type': 'audio/mpeg',
    'Content-Disposition': `attachment; filename="${fileName}"`,
    'Cache-Control': 'private, max-age=3600',
    'Access-Control-Allow-Origin': '*',
  });
  stream.pipe(res);
}

async function processJob(job) {
  activeJobCount += 1;
  updateJob(job, { status: 'processing' });
  logEvent('job-processing', {
    youtubeId: job.youtubeId,
    jobId: job.id,
  });

  const jobWorkDir = path.join(WORK_DIR, job.id);
  const tempTemplate = path.join(jobWorkDir, 'audio.%(ext)s');

  try {
    await fsp.mkdir(jobWorkDir, { recursive: true });
    await runYtDlp(job.youtubeId, tempTemplate, job);

    const producedFiles = await fsp.readdir(jobWorkDir);
    const audioFileName = producedFiles.find((name) => name.startsWith('audio.'));
    if (!audioFileName) {
      throw new Error('yt-dlp nao gerou arquivo de audio.');
    }

    const tempAudioPath = path.join(jobWorkDir, audioFileName);
    await runFfmpeg(tempAudioPath, job.outputPath);

    cacheIndex.set(job.youtubeId, {
      youtubeId: job.youtubeId,
      outputFileName: job.outputFileName,
      contentType: job.contentType,
      updatedAt: new Date().toISOString(),
    });
    await saveCacheIndex();
    updateJob(job, { status: 'completed' });
    logEvent('job-completed', {
      youtubeId: job.youtubeId,
      jobId: job.id,
      file: job.outputFileName,
    });
  } catch (error) {
    updateJob(job, {
      status: 'failed',
      error: normalizeErrorMessage(error),
    });
    logEvent('job-failed', {
      youtubeId: job.youtubeId,
      jobId: job.id,
      error: job.error,
    });
  } finally {
    activeJobCount -= 1;
    await fsp.rm(jobWorkDir, { recursive: true, force: true });
  }
}

function updateJob(job, patch) {
  Object.assign(job, patch, { updatedAt: new Date().toISOString() });
}

async function runYtDlp(youtubeId, outputTemplate, job) {
  const videoUrl = `https://www.youtube.com/watch?v=${youtubeId}`;
  const cookieArgs = ytDlpCookiesPath ? ['--cookies', ytDlpCookiesPath] : [];
  const formatStrategies = ['bestaudio/best', 'bestaudio', 'ba', 'best', 'bestvideo+bestaudio/best', ''];
  const strategies = [
    {
      name: 'android-web',
      extractorArgs: 'youtube:player_client=android,web;player_skip=webpage,configs',
    },
    {
      name: 'ios-web',
      extractorArgs: 'youtube:player_client=ios,web;player_skip=webpage,configs',
    },
    {
      name: 'tv-android-web',
      extractorArgs: 'youtube:player_client=tv,android,web;player_skip=webpage,configs',
    },
  ];

  let lastError = null;

  for (const strategy of strategies) {
    for (const format of formatStrategies) {
      try {
        const formatArgs = format ? ['--format', format] : [];
        logEvent('yt-dlp-attempt', {
          youtubeId,
          jobId: job?.id || 'unknown',
          strategy: strategy.name,
          format: format || 'default',
        });
        await runCommand(
          YT_DLP_BIN,
          [
            ...YT_DLP_ARGS,
            ...cookieArgs,
            '--user-agent',
            YT_DLP_USER_AGENT,
            '--referer',
            'https://www.youtube.com/',
            '--add-header',
            'Accept-Language:en-US,en;q=0.9',
            '--add-header',
            'Origin:https://www.youtube.com',
            '--extractor-retries',
            '5',
            '--fragment-retries',
            '5',
            '--retries',
            '5',
            '--retry-sleep',
            '2',
            '--no-playlist',
            '--no-warnings',
            '--restrict-filenames',
            '--no-check-certificates',
            ...formatArgs,
            '--extractor-args',
            strategy.extractorArgs,
            '--output',
            outputTemplate,
            videoUrl,
          ],
          `Falha ao baixar audio com yt-dlp [${strategy.name}/${format || 'default'}].`,
        );
        logEvent('yt-dlp-success', {
          youtubeId,
          jobId: job?.id || 'unknown',
          strategy: strategy.name,
          format: format || 'default',
        });
        return;
      } catch (error) {
        lastError = error;
        logEvent('yt-dlp-retry', {
          youtubeId,
          jobId: job?.id || 'unknown',
          strategy: strategy.name,
          format: format || 'default',
          error: normalizeErrorMessage(error),
        });
      }
    }
  }

  const formatList = await listYtDlpFormats(videoUrl, cookieArgs);
  if (formatList) {
    logEvent('yt-dlp-formats', {
      youtubeId,
      jobId: job?.id || 'unknown',
      formats: formatList,
    });
  }

  throw lastError || new Error('Falha ao baixar audio com yt-dlp.');
}

async function listYtDlpFormats(videoUrl, cookieArgs) {
  try {
    const output = await runCommandCaptureStdout(
      YT_DLP_BIN,
      [
        ...YT_DLP_ARGS,
        ...cookieArgs,
        '--user-agent',
        YT_DLP_USER_AGENT,
        '--referer',
        'https://www.youtube.com/',
        '--add-header',
        'Accept-Language:en-US,en;q=0.9',
        '--add-header',
        'Origin:https://www.youtube.com',
        '--list-formats',
        '--no-playlist',
        '--no-warnings',
        '--no-check-certificates',
        videoUrl,
      ],
      'Falha ao listar formatos com yt-dlp.',
    );

    return output
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter(Boolean)
      .slice(-15)
      .join(' | ')
      .slice(0, 4000);
  } catch (error) {
    logEvent('yt-dlp-formats-failed', {
      error: normalizeErrorMessage(error),
    });
    return '';
  }
}

async function ensureCookiesFile() {
  if (YOUTUBE_COOKIES_PATH) {
    return YOUTUBE_COOKIES_PATH;
  }

  const rawCookies =
    decodeBase64Value(YOUTUBE_COOKIES_B64_PARTS) ||
    decodeBase64Value(YOUTUBE_COOKIES_B64) ||
    normalizeCookiePayload(YOUTUBE_COOKIES_PARTS) ||
    normalizeCookiePayload(YOUTUBE_COOKIES);

  if (!rawCookies) {
    return '';
  }

  const cookiesPath = path.join(RUNTIME_DIR, 'youtube-cookies.txt');
  await fsp.writeFile(cookiesPath, rawCookies, 'utf8');
  return cookiesPath;
}

function collectEnvParts(prefix) {
  return Object.entries(process.env)
    .filter(([key, value]) => key.startsWith(prefix) && value)
    .sort(([left], [right]) => {
      const leftIndex = Number(left.slice(prefix.length));
      const rightIndex = Number(right.slice(prefix.length));
      return leftIndex - rightIndex;
    })
    .map(([, value]) => value)
    .join('');
}

function runFfmpeg(inputPath, outputPath) {
  return runCommand(
    FFMPEG_BIN,
    [
      '-y',
      '-i',
      inputPath,
      '-vn',
      '-codec:a',
      'libmp3lame',
      '-q:a',
      '2',
      outputPath,
    ],
    'Falha ao converter audio com ffmpeg.',
  );
}

function runCommand(command, args, fallbackMessage) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      windowsHide: true,
    });

    let stderr = '';

    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    child.on('error', (error) => {
      reject(
        new Error(`${fallbackMessage} ${error.message}`.trim()),
      );
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolve();
        return;
      }

      reject(
        new Error(`${fallbackMessage} ${stderr.trim()}`.trim()),
      );
    });
  });
}

function runCommandCaptureStdout(command, args, fallbackMessage) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      windowsHide: true,
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (chunk) => {
      stdout += chunk.toString();
    });

    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    child.on('error', (error) => {
      reject(new Error(`${fallbackMessage} ${error.message}`.trim()));
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolve(stdout.trim());
        return;
      }

      reject(new Error(`${fallbackMessage} ${stderr.trim()}`.trim()));
    });
  });
}

function cleanupExpiredJobs() {
  const maxAgeMs = MAX_JOB_AGE_MINUTES * 60 * 1000;
  const now = Date.now();

  for (const job of jobs.values()) {
    const age = now - new Date(job.updatedAt).getTime();
    if (age < maxAgeMs) {
      continue;
    }

    jobs.delete(job.id);
    if (job.outputPath && !job.retainFile) {
      fsp.rm(job.outputPath, { force: true }).catch(() => {});
    }
  }
}

async function loadCacheIndex() {
  try {
    const raw = await fsp.readFile(CACHE_INDEX_PATH, 'utf8');
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) {
      return;
    }

    for (const entry of parsed) {
      if (!entry || typeof entry !== 'object') {
        continue;
      }

      const youtubeId = typeof entry.youtubeId === 'string' ? entry.youtubeId : '';
      const outputFileName =
        typeof entry.outputFileName === 'string' ? entry.outputFileName : '';
      if (!youtubeId || !outputFileName) {
        continue;
      }

      const outputPath = path.join(FILES_DIR, outputFileName);
      try {
        await fsp.access(outputPath, fs.constants.R_OK);
      } catch {
        continue;
      }

      cacheIndex.set(youtubeId, {
        youtubeId,
        outputFileName,
        contentType:
          typeof entry.contentType === 'string' && entry.contentType
            ? entry.contentType
            : 'audio/mpeg',
        updatedAt:
          typeof entry.updatedAt === 'string' && entry.updatedAt
            ? entry.updatedAt
            : new Date().toISOString(),
      });
    }
  } catch (error) {
    if (error && error.code === 'ENOENT') {
      return;
    }
    console.error('[download-proxy] failed to load cache index', error);
  }
}

async function saveCacheIndex() {
  const payload = JSON.stringify([...cacheIndex.values()], null, 2);
  await fsp.writeFile(CACHE_INDEX_PATH, payload, 'utf8');
}

async function getValidCacheEntry(youtubeId) {
  const entry = cacheIndex.get(youtubeId);
  if (!entry) {
    return null;
  }

  const outputPath = path.join(FILES_DIR, entry.outputFileName);
  try {
    await fsp.access(outputPath, fs.constants.R_OK);
    return entry;
  } catch {
    cacheIndex.delete(youtubeId);
    await saveCacheIndex();
    return null;
  }
}

function findReusableJob(youtubeId) {
  for (const job of jobs.values()) {
    if (
      job.youtubeId === youtubeId &&
      (job.status === 'queued' ||
        job.status === 'processing' ||
        job.status === 'completed')
    ) {
      return job;
    }
  }

  return null;
}

function buildOutputFileName(song, youtubeId) {
  const safeBaseName = sanitizeFileBaseName(
    `${song.title || 'track'}-${song.artist || 'unknown'}`,
  );
  const safeYoutubeId = sanitizeFileBaseName(youtubeId);
  return `${safeBaseName}-${safeYoutubeId}.mp3`;
}

async function readJsonBody(req) {
  const chunks = [];

  for await (const chunk of req) {
    chunks.push(Buffer.from(chunk));
  }

  const raw = Buffer.concat(chunks).toString('utf8').trim();
  if (!raw) {
    return {};
  }

  try {
    return JSON.parse(raw);
  } catch {
    throw new HttpError(400, 'JSON invalido.');
  }
}

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
  });
  res.end(JSON.stringify(payload));
}

function resolvePublicBaseUrl(req) {
  const forwardedProto = headerValue(req.headers['x-forwarded-proto']);
  const forwardedHost = headerValue(req.headers['x-forwarded-host']);
  const host = headerValue(req.headers.host);

  if (forwardedHost || host) {
    const protocol = forwardedProto || (host && host.startsWith('localhost') ? 'http' : 'https');
    return `${protocol}://${forwardedHost || host}`.replace(/\/+$/, '');
  }

  return BASE_URL;
}

function headerValue(value) {
  if (Array.isArray(value)) {
    return value[0] || '';
  }
  return typeof value === 'string' ? value.trim() : '';
}

function sanitizeFileBaseName(input) {
  const normalized = String(input || 'track')
    .normalize('NFKD')
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^[-_.]+|[-_.]+$/g, '')
    .toLowerCase();

  return normalized || 'track';
}

function normalizeErrorMessage(error) {
  if (error instanceof HttpError) {
    return error.message;
  }

  const message = error instanceof Error && error.message
    ? error.message
    : 'Falha no backend de download.';

  if (isYoutubeAuthError(message)) {
    return (
      'YouTube bloqueou o servidor por verificacao anti-bot. ' +
      'Configure YOUTUBE_COOKIES_B64 no Railway com cookies exportados do YouTube e reinicie o servico.'
    );
  }

  return message;
}

function isYoutubeAuthError(message) {
  const normalized = String(message || '').toLowerCase();
  return (
    normalized.includes('sign in to confirm') ||
    normalized.includes('not a bot') ||
    normalized.includes('--cookies-from-browser') ||
    normalized.includes('use --cookies')
  );
}

function logEvent(event, details) {
  const timestamp = new Date().toISOString();
  const payload = Object.entries(details || {})
    .map(([key, value]) => `${key}=${String(value)}`)
    .join(' ');
  console.log(`[download-proxy] ${timestamp} ${event}${payload ? ` ${payload}` : ''}`);
}

function loadEnv(filePath) {
  if (!fs.existsSync(filePath)) {
    return;
  }

  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) {
      continue;
    }

    const separator = trimmed.indexOf('=');
    if (separator <= 0) {
      continue;
    }

    const key = trimmed.slice(0, separator).trim();
    const value = trimmed.slice(separator + 1).trim();
    if (!process.env[key]) {
      process.env[key] = value;
    }
  }
}

function splitCommandArgs(input) {
  const value = String(input || '').trim();
  if (!value) {
    return [];
  }

  const parts = value.match(/(?:[^\s"]+|"[^"]*")+/g);
  if (!parts) {
    return [];
  }

  return parts.map((part) => {
    if (part.startsWith('"') && part.endsWith('"')) {
      return part.slice(1, -1);
    }
    return part;
  });
}

function decodeBase64Value(input) {
  const value = String(input || '').trim();
  if (!value) {
    return '';
  }

  try {
    return Buffer.from(value, 'base64').toString('utf8').trim();
  } catch {
    return '';
  }
}

function normalizeCookiePayload(input) {
  const value = String(input || '').trim();
  if (!value) {
    return '';
  }

  return value.replace(/\\n/g, '\n').trim();
}

class HttpError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
  }
}

bootstrap().catch((error) => {
  console.error('[download-proxy] failed to start', error);
  process.exitCode = 1;
});
