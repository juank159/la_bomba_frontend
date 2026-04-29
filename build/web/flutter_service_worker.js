// Self-destruct service worker.
// Reemplaza al SW viejo que estaba cacheando agresivamente. Al activarse:
//   - Limpia todas las entradas de Cache Storage
//   - Toma control de las pestañas (clients.claim)
//   - Se desregistra a sí mismo
//   - Navega cada pestaña a su URL para forzar recarga sin SW
//
// IMPORTANTE: NO definimos un listener de 'fetch'. Si registramos un listener
// vacío (sin llamar event.respondWith), algunos navegadores quedan esperando
// la respuesta del SW indefinidamente → pantalla en blanco. Sin listener, el
// navegador maneja todas las requests directamente sin pasar por el SW.
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
