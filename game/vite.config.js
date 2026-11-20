import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  // Use relative base so assets resolve properly on custom domains (orvexgames.me) and subpaths
  base: './',
  server: {
    host: '127.0.0.1',
    port: 5173,
    fs: {
      allow: ['..']
    }
  }
});
