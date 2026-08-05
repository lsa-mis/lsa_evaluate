import * as esbuild from 'esbuild'
import { sentryEsbuildPlugin } from '@sentry/esbuild-plugin'
import { readdirSync } from 'node:fs'
import { join } from 'node:path'
import { execSync } from 'node:child_process'

const entryPoints = readdirSync('app/javascript')
  .filter((name) => /\.(js|ts|jsx|tsx)$/.test(name))
  .map((name) => join('app/javascript', name))

const release =
  process.env.SENTRY_RELEASE ||
  (() => {
    try {
      return execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim()
    } catch {
      return undefined
    }
  })()

const plugins = []

// Upload source maps when deploy/CI provides an auth token (skip locally otherwise).
if (process.env.SENTRY_AUTH_TOKEN) {
  plugins.push(
    sentryEsbuildPlugin({
      org: process.env.SENTRY_ORG || 'wads-rails-lsa-um',
      project: process.env.SENTRY_PROJECT || 'evaluate',
      authToken: process.env.SENTRY_AUTH_TOKEN,
      release: release ? { name: release } : undefined,
      sourcemaps: {
        assets: ['./app/assets/builds/**'],
        filesToDeleteAfterUpload: ['./app/assets/builds/**/*.map']
      }
    })
  )
}

await esbuild.build({
  entryPoints,
  bundle: true,
  sourcemap: true,
  format: 'esm',
  outdir: 'app/assets/builds',
  publicPath: '/assets',
  plugins
})
