import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      dompurify: path.resolve(__dirname, 'src/shims/dompurify.ts'),
      canvg: path.resolve(__dirname, 'src/shims/dummy.ts'),
      html2canvas: path.resolve(__dirname, 'src/shims/dummy.ts'),
    },
  },
})