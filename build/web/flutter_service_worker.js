// Self-destruct service worker.
// Replaces any old Flutter SW that was caching aggressively. On activation it
// clears every Cache Storage entry, claims all clients, unregisters itself,
// and asks the controlled tabs to reload. Result: clients running a stale
// bundle pick up the latest one immediately, and no SW is left behind.
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    try {
      const keys = await caches.keys();
      await Promise.all(keys.map((k) => caches.delete(k)));
    } catch (_) {}
    try { await self.clients.claim(); } catch (_) {}
    try { await self.registration.unregister(); } catch (_) {}
    try {
      const clients = await self.clients.matchAll({ type: 'window' });
      for (const client of clients) client.navigate(client.url);
    } catch (_) {}
  })());
});

// Pass-through fetch: never serve from cache.
self.addEventListener('fetch', (event) => {
  // No-op: dejamos que el navegador maneje todas las requests directamente.
});
