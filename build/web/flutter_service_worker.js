// Reemplazo neutro del Service Worker: expulsa al SW viejo y se queda activo
// pero inerte. Sin fetch listener: todas las requests van directas al network.
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
  })());
});
