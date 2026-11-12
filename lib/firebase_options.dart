// Configuração do Firebase para o projeto de TESTE (time-lobao-teste).
// As chaves abaixo identificam o app no Firebase e não são segredos:
// a proteção dos dados vem das regras de segurança (firestore.rules).
// Para produção, gere um novo arquivo apontando para o projeto limpo.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase ainda não configurado para $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAs7VuQlyx5akOBJ4XSTEQ1TE-0yDSeGMw',
    appId: '1:540869919988:web:c26a3b2c741e3c2b430aa1',
    messagingSenderId: '540869919988',
    projectId: 'time-lobao-teste',
    authDomain: 'time-lobao-teste.firebaseapp.com',
    storageBucket: 'time-lobao-teste.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXFedCa5it6Vvl3olPWDzIXrvfAVcB6Dc',
    appId: '1:540869919988:android:dbb450ae48659523430aa1',
    messagingSenderId: '540869919988',
    projectId: 'time-lobao-teste',
    storageBucket: 'time-lobao-teste.firebasestorage.app',
  );
}
