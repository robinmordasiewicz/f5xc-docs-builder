FROM node:24-alpine AS builder
LABEL org.opencontainers.image.description="f5xc-docs-builder"
WORKDIR /app

# Install Chromium and dependencies for Puppeteer (PDF generation)
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    font-noto \
    font-noto-cjk

# Use system Chromium instead of Puppeteer downloading its own
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Install deps (cached layer)
COPY package*.json ./
RUN npm ci --legacy-peer-deps

# Copy framework code
COPY . .

# Remove placeholder content
RUN rm -rf src/content/docs/*

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
