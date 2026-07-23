// Entry point for the build script in your package.json
import * as Sentry from "@sentry/browser"
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"
import Sortable from "sortablejs"

import "trix"
import "@rails/actiontext"

const sentryDsn = document.querySelector('meta[name="sentry-dsn"]')?.content

if (sentryDsn) {
  const environment =
    document.querySelector('meta[name="sentry-environment"]')?.content || "production"
  const release = document.querySelector('meta[name="sentry-release"]')?.content
  const isProduction = environment === "production"

  Sentry.init({
    dsn: sentryDsn,
    environment,
    release: release || undefined,
    integrations: [Sentry.browserTracingIntegration()],
    // Match server-side sampling; keep all browser errors
    tracesSampleRate: isProduction ? 0.1 : 1.0,
    // Ignore common extension / noise errors
    ignoreErrors: [
      "ResizeObserver loop limit exceeded",
      "ResizeObserver loop completed with undelivered notifications",
      "Non-Error promise rejection captured",
      /^Loading CSS chunk/,
      /^Loading chunk/
    ],
    beforeSend(event) {
      // Drop events from browser extensions
      if (event.exception?.values?.some((ex) =>
        /chrome-extension:|moz-extension:|safari-extension:/i.test(ex.stacktrace?.frames?.[0]?.filename || "")
      )) {
        return null
      }
      return event
    }
  })
}

window.Sortable = Sortable;
