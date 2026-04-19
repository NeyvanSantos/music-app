FROM node:20-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg python3 python3-pip \
    && python3 -m pip install --break-system-packages --no-cache-dir yt-dlp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json ./
COPY server.js ./
COPY README.md ./

ENV NODE_ENV=production
ENV PORT=8080
ENV HOST=0.0.0.0
ENV STORAGE_DIR=/data
ENV YT_DLP_BIN=python3
ENV YT_DLP_ARGS="-m yt_dlp"
ENV FFMPEG_BIN=ffmpeg

RUN mkdir -p /data

EXPOSE 8080

CMD ["node", "server.js"]
