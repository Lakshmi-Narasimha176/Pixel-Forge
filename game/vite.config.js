import { defineConfig } from 'vite';
import path from 'path';

export default defineConfig({
  server: {
    host: '127.0.0.1',
    port: 5173,
    fs: {
      allow: ['..']
    }
  }
});
