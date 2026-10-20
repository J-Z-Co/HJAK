import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async connect() {
    if (!document.querySelector('meta[name="phoenix-revalidate"]')) return
    const etag = document.querySelector('meta[name="phoenix-etag"]')?.content
    if (!etag) return

    const response = await fetch(window.location.href, {
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "If-None-Match": etag,
        "X-Phoenix-Revalidate": "1"
      },
      credentials: "same-origin"
    })
    if (response.status === 304) return

    const html = await response.text()
    if (!html.includes("<turbo-stream")) return
    window.Turbo?.renderStreamMessage(html)

    const match = document.cookie.match(/(?:^|; )phoenix_cache=([^;]+)/)
    if (!match || !navigator.serviceWorker?.controller) return
    navigator.serviceWorker.controller.postMessage({
      type: "refresh",
      url: window.location.href,
      cache: `phoenix-${decodeURIComponent(match[1])}`
    })
  }
}
