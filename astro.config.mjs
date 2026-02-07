import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import react from '@astrojs/react';
import remarkMermaid from './src/plugins/remark-mermaid.mjs';

const title = process.env.DOCS_TITLE || 'Documentation';
const site = process.env.DOCS_SITE || 'https://robinmordasiewicz.github.io';
const base = process.env.DOCS_BASE || '/';

export default defineConfig({
  site,
  base,
  markdown: {
    remarkPlugins: [remarkMermaid],
  },
  integrations: [
    starlight({
      title,
      customCss: [
        './theme/fonts/font-face.css',
        './theme/styles/custom.css',
      ],
      logo: {
        src: './theme/assets/f5-logo.svg',
      },
      components: {
        Footer: './theme/components/Footer.astro',
      },
      social: [
        {
          label: 'GitHub',
          icon: 'github',
          href: `https://github.com/${process.env.GITHUB_REPOSITORY || ''}`,
        },
      ],
      sidebar: [
        {
          label: process.env.SIDEBAR_LABEL || 'Guide',
          autogenerate: { directory: 'guide' },
        },
      ],
    }),
    react(),
  ],
});
