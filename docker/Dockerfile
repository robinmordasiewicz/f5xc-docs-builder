FROM node:24-alpine AS builder
LABEL org.opencontainers.image.description="f5xc-docs-builder"
WORKDIR /app

# Install deps (cached layer)
COPY package*.json ./
RUN npm ci

# Copy framework code
COPY . .

# Remove placeholder content
RUN rm -rf src/content/docs/*

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
