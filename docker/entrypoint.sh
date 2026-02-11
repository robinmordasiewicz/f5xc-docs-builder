#!/bin/sh
set -e

CONTENT_DIR="${CONTENT_DIR:-/content/docs}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
GENERATE_PDF="${GENERATE_PDF:-false}"

# Update dependencies to latest versions
npm install --legacy-peer-deps
npm update --legacy-peer-deps

# Copy Astro config from theme package (single source of truth)
cp /app/node_modules/f5xc-docs-theme/astro.config.mjs /app/astro.config.mjs
cp /app/node_modules/f5xc-docs-theme/src/content.config.ts /app/src/content.config.ts

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

# Extract description from index.mdx frontmatter (if not set via env)
if [ -z "$DOCS_DESCRIPTION" ] && [ -f /app/src/content/docs/index.mdx ]; then
  DOCS_DESCRIPTION=$(grep -m1 '^description:' /app/src/content/docs/index.mdx | sed 's/description: *["]*//;s/["]*$//' || echo "")
  export DOCS_DESCRIPTION
fi

# Read optional LLM links from llms-links.json (if present in content)
if [ -z "$LLMS_OPTIONAL_LINKS" ] && [ -f /app/src/content/docs/llms-links.json ]; then
  LLMS_OPTIONAL_LINKS=$(cat /app/src/content/docs/llms-links.json)
  export LLMS_OPTIONAL_LINKS
  rm /app/src/content/docs/llms-links.json
fi

# Extract base path from repo name (if not set via env)
if [ -z "$DOCS_BASE" ] && [ -n "$GITHUB_REPOSITORY" ]; then
  DOCS_BASE="/${GITHUB_REPOSITORY#*/}"
  export DOCS_BASE
fi

# Build
npm run build

# --- PDF Generation (optional) ---
if [ "$GENERATE_PDF" = "true" ]; then
  echo "PDF generation enabled. Starting preview server..."

  PDF_FILENAME="${PDF_FILENAME:-docs}"

  # Construct preview URL with base path
  PREVIEW_BASE="${DOCS_BASE:-/}"
  PREVIEW_URL="http://localhost:4321${PREVIEW_BASE}"

  # Start preview server in background
  npm run preview &
  PREVIEW_PID=$!

  # Wait for preview server to be ready
  echo "Waiting for preview server to start..."
  RETRIES=0
  MAX_RETRIES=30
  until wget -q --spider "$PREVIEW_URL" 2>/dev/null; do
    RETRIES=$((RETRIES + 1))
    if [ "$RETRIES" -ge "$MAX_RETRIES" ]; then
      echo "ERROR: Preview server did not start within ${MAX_RETRIES} seconds"
      kill "$PREVIEW_PID" 2>/dev/null || true
      exit 1
    fi
    sleep 1
  done
  echo "Preview server is ready at $PREVIEW_URL"

  # Generate PDF into dist so it ships with the static site
  mkdir -p /app/dist/_pdf
  echo "Generating PDF..."
  npx starlight-to-pdf "$PREVIEW_URL" \
    --browser-executable /usr/bin/chromium-browser \
    --path /app/dist/_pdf \
    --filename "$PDF_FILENAME" \
    --pdf-outline \
    --print-bg

  echo "PDF generated at /app/dist/_pdf/${PDF_FILENAME}.pdf"

  # Stop preview server
  kill "$PREVIEW_PID" 2>/dev/null || true
  wait "$PREVIEW_PID" 2>/dev/null || true
  echo "Preview server stopped."
fi

# Copy output
if [ -d "$OUTPUT_DIR" ]; then
  cp -r /app/dist/* "$OUTPUT_DIR"/
fi
