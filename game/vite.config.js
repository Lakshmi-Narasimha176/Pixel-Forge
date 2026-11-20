import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  // GitHub Pages serves this project from /Pixel-Forge/ rather than the domain root.
  base: '/Pixel-Forge/',
  server: {
    host: '127.0.0.1',
    port: 5173,
    fs: {
      allow: ['..']
    }
  }
});
