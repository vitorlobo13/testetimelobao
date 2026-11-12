// Service worker do Firebase Cloud Messaging: mostra as notificações push
// quando o app (web/PWA) está fechado ou em segundo plano.
importScripts('https://www.gstatic.com/firebasejs/11.0.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.0.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAs7VuQlyx5akOBJ4XSTEQ1TE-0yDSeGMw',
  appId: '1:540869919988:web:c26a3b2c741e3c2b430aa1',
  messagingSenderId: '540869919988',
  projectId: 'time-lobao-teste',
  authDomain: 'time-lobao-teste.firebaseapp.com',
  storageBucket: 'time-lobao-teste.firebasestorage.app',
});

// As mensagens enviadas pelas Cloud Functions trazem o bloco
// "notification", que o SDK exibe sozinho em segundo plano.
firebase.messaging();

// Ao tocar na notificação, abre (ou foca) o app.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({type: 'window', includeUncontrolled: true}).then((list) => {
      for (const client of list) {
        if ('focus' in client) return client.focus();
      }
      return clients.openWindow('/');
    }),
  );
});
