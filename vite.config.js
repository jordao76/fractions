import { defineConfig } from 'vite';

export default defineConfig({
  base: '/fractions/',
  build: {
    outDir: 'dist',
  },
  test: {
    include: ['test/**/*.test.js'],
  },
});
