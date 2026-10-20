const TTL = 6 * 60 * 60 * 1000

function cacheable(path) {
  if (path.startsWith("/indices")) return true
  if (path === "/groups") return true
  if (/^\/groups\/[^/]+$/.test(path)) return true
  if (/^\/groups\/[^/]+\/year$/.test(path)) return true
  if (/^\/groups\/[^/]+\/members\/[^/]+\/indices/.test(path)) return true
  return false
}

function cacheName(request) {
  const cookie = request.headers.get("cookie") || ""
  const match = cookie.match(/(?:^|; )phoenix_cache=([^;]+)/)
  return match ? `phoenix-${decodeURIComponent(match[1])}` : null
}

async function clearCaches() {
  const keys = await caches.keys()
  await Promise.all(keys.filter((key) => key.startsWith("phoenix-")).map((key) => caches.delete(key)))
}

async function store(cache, request, response) {
  const headers = new Headers(response.headers)
  headers.set("x-phoenix-cached-at", Date.now().toString())
  const stored = new Response(await response.clone().blob(), { status: response.status, statusText: response.statusText, headers })
  await cache.put(request, stored)
}

self.addEventListener("fetch", (event) => {
  const request = event.request
  if (request.method !== "GET" || request.mode !== "navigate") return
  const url = new URL(request.url)
  if (url.origin !== self.location.origin) return

  const name = cacheName(request)
  if (!name) {
    event.waitUntil(clearCaches())
    return
  }
  if (!cacheable(url.pathname)) return

  event.respondWith((async () => {
    const cache = await caches.open(name)
    const cached = await cache.match(request)
    const cachedAt = Number(cached?.headers.get("x-phoenix-cached-at") || 0)
    if (cached && Date.now() - cachedAt < TTL) return cached
    try {
      const response = await fetch(request)
      if (response.ok) await store(cache, request, response)
      return response
    } catch (error) {
      if (cached) return cached
      throw error
    }
  })())
})

self.addEventListener("message", (event) => {
  if (event.data?.type !== "refresh" || !event.data.cache || !event.data.url) return
  event.waitUntil((async () => {
    const request = new Request(event.data.url, { credentials: "same-origin" })
    const response = await fetch(request)
    if (!response.ok) return
    const cache = await caches.open(event.data.cache)
    await store(cache, request, response)
  })())
})
