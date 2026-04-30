// Reemplazo neutro del Service Worker: expulsa al SW viejo (que tenía bugs de
// caching/listeners colgantes) y se queda activo pero inerte.
//
// Diseño:
//   - install: skipWaiting() para que reemplace al SW viejo de inmediato
//   - activate: limpia Cache Storage + clients.claim() para tomar control
//   - NO hay listener de 'fetch' → todas las requests van directas al network
//
// No nos auto-desregistramos ni navegamos los clients porque eso provocaba
// recargas en bucle cuando flutter_bootstrap.js volvía a registrar el SW.
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
