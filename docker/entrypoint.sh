#!/bin/sh
set -e

CONTENT_DIR="${CONTENT_DIR:-/content/docs}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"

# Update dependencies to latest versions
npm install
npm update

# Copy Astro config from theme package
cp /app/node_modules/f5xc-docs-theme/astro.config.mjs /app/astro.config.mjs

# Patch: ensure customCss is initialized (workaround for theme plugin bug)
sed -i "s/title: process.env.DOCS_TITLE || 'Documentation',/title: process.env.DOCS_TITLE || 'Documentation',\n      customCss: [],/" /app/astro.config.mjs

# Inject content
if [ -d "$CONTENT_DIR" ]; then
  cp -r "$CONTENT_DIR"/* /app/src/content/docs/
else
  echo "ERROR: No content found at $CONTENT_DIR"
  exit 1
fi

# Extract title from index.mdx frontmatter (if not set via env)
if [ -z "$DOCS_TITLE" ] && [ -f /app/src/content/docs/index.mdx ]; then
  DOCS_TITLE=$(grep -m1 '^title:' /app/src/content/docs/index.mdx | sed 's/title: *["]*//;s/["]*$//' || echo "Documentation")
  export DOCS_TITLE
fi

# Extract base path from repo name (if not set via env)
if [ -z "$DOCS_BASE" ] && [ -n "$GITHUB_REPOSITORY" ]; then
  DOCS_BASE="/${GITHUB_REPOSITORY#*/}"
  export DOCS_BASE
fi

# Build
npm run build

# Copy output
if [ -d "$OUTPUT_DIR" ]; then
  cp -r /app/dist/* "$OUTPUT_DIR"/
fi
