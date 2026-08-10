import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

import tailwindcss from '@tailwindcss/vite'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig(({ mode }) => {
  const isDev = mode === 'development'

  return {
    plugins: [
      vue(),
      isDev && vueDevTools(),
      tailwindcss(),

      VitePWA({
        registerType: 'autoUpdate',
        includeAssets: ['favicon.ico', 'apple-touch-icon.png'],
        manifest: {
          name: 'FuelGuard Management System',
          short_name: 'FuelGuard',
          description: 'Sistem Manajemen Pengetap FuelGuard',
          theme_color: '#143d2e',
          background_color: '#f5f5f5',
          display: 'standalone',
          orientation: 'portrait',
          icons: [
            {
              src: 'pwa-192x192.png',
              sizes: '192x192',
              type: 'image/png'
            },
            {
              src: 'pwa-512x512.png',
              sizes: '512x512',
              type: 'image/png'
            },
            {
              src: 'pwa-512x512.png',
              sizes: '512x512',
              type: 'image/png',
              purpose: 'any maskable'
            }
          ]
        },
        workbox: {
          globPatterns: ['**/*.{js,css,html,ico,png,svg,jpg,jpeg,woff2,woff}'],
          maximumFileSizeToCacheInBytes: 4000000,
          runtimeCaching: [
            {
              urlPattern: /^https:\/\/fonts\.googleapis\.com\/.*/i,
              handler: 'StaleWhileRevalidate',
              options: {
                cacheName: 'google-fonts-stylesheets'
              }
            },
            {
              urlPattern: /^https:\/\/fonts\.gstatic\.com\/.*/i,
              handler: 'CacheFirst',
              options: {
                cacheName: 'google-fonts-webfonts',
                expiration: {
                  maxEntries: 30,
                  maxAgeSeconds: 60 * 60 * 24 * 365 // 1 year
                },
                cacheableResponse: {
                  statuses: [0, 200]
                }
              }
            },
            {
              urlPattern: /^https:\/\/.*\.supabase\.co\/rest\/v1\/(operator_profiles|region_codes|fuel_prices|spbu).*/i,
              handler: 'NetworkFirst',
              options: {
                cacheName: 'supabase-lookups-cache',
                expiration: {
                  maxEntries: 50,
                  maxAgeSeconds: 60 * 60 * 24 * 7 // 7 days
                },
                networkTimeoutSeconds: 5
              }
            }
          ]
        },
        devOptions: {
          enabled: isDev
        }
      })
    ].filter(Boolean),

    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url))
      }
    },

    esbuild: {
      drop: isDev ? [] : ['console', 'debugger']
    },

    build: {
      sourcemap: false,
      rollupOptions: {
        output: {
          manualChunks: {
            'chart-vendor': ['chart.js', 'vue-chartjs'],
            'supabase-vendor': ['@supabase/supabase-js']
          }
        }
      }
    }
  }
})
