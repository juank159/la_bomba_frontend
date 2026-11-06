// Service worker de notificaciones web (Firebase Cloud Messaging).
//
// Recibe las notificaciones cuando la pestaña de La Bomba NO está al frente
// (minimizada, en otra pestaña o con el navegador en segundo plano). La
// notificación visible la muestra Firebase sola (viene con bloque
// `notification`). Además, si el mensaje trae `voice` (pagos Bre-B), le pide
// a una pestaña abierta que lo diga en voz alta: el service worker no puede
// hablar, la página sí (ver el script al final de index.html).
//
// La configuración debe ser LA MISMA que `DefaultFirebaseOptions.web` en
// lib/firebase_options.dart.

importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBoXzj20R52nGk-7Ag3juFxGyS9eGg0MVg',
  appId: '1:712051635167:web:5f63d63dc38934aa67ca6a',
  messagingSenderId: '712051635167',
  projectId: 'la-bomba-414b6',
  authDomain: 'la-bomba-414b6.firebaseapp.com',
  storageBucket: 'la-bomba-414b6.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(async (payload) => {
  const voice = payload && payload.data && payload.data.voice;
  if (!voice) return;
  const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
  // Una sola pestaña habla (si hay varias abiertas, no en coro).
  if (windows.length > 0) {
    windows[0].postMessage({ type: 'labomba_voice', text: voice });
  }
});

// Tocar la notificación lo maneja Firebase solo: abre/enfoca `fcmOptions.link`
// (la URL de la app que manda el servidor).
