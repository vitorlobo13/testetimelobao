import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Chave pública Web Push (Firebase Console → Cloud Messaging).
/// Não é segredo: identifica o app para o serviço de push do navegador.
const String kWebPushVapidKey =
    'BGywemUJa-GaltcbYwTtzoUlRSCgQWdB6ynwbn57uDA_J9voRr5UmPLf8HN3Axr_87vItsbYnms8NYMYH-sDaIg';

/// Registra o aparelho para receber push (notificação com o app fechado).
/// O token fica em `users/{uid}/fcmTokens/{token}`; as Cloud Functions
/// enviam para todos os tokens do usuário.
class PushService {
  PushService({FirebaseMessaging? messaging, FirebaseFirestore? firestore})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  StreamSubscription<String>? _refreshSub;

  /// Push é suportado neste navegador/aparelho?
  Future<bool> isSupported() => _messaging.isSupported();

  /// Permissão já concedida (não pergunta nada ao usuário).
  Future<bool> isGranted() async {
    if (!await isSupported()) return false;
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Pede permissão (deve ser chamado a partir de um toque do usuário,
  /// exigência do iPhone) e registra o token. Retorna se ficou ativo.
  Future<bool> enable(String uid) async {
    if (!await isSupported()) return false;
    final settings = await _messaging.requestPermission();
    final ok = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (ok) await registerToken(uid);
    return ok;
  }

  /// Salva o token atual (usado ao abrir o app, se a permissão já existir).
  Future<void> registerToken(String uid) async {
    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? kWebPushVapidKey : null,
      );
      if (token != null) await _save(uid, token);
      await _refreshSub?.cancel();
      _refreshSub = _messaging.onTokenRefresh.listen((t) => _save(uid, t));
    } on Exception catch (e) {
      developer.log('Não foi possível registrar o push', error: e);
    }
  }

  Future<void> _save(String uid, String token) =>
      _firestore.doc('users/$uid/fcmTokens/$token').set({
        'platform': kIsWeb ? 'web' : 'android',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Remove o token deste aparelho (ao sair da conta).
  Future<void> unregister(String uid) async {
    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? kWebPushVapidKey : null,
      );
      if (token != null) {
        await _firestore.doc('users/$uid/fcmTokens/$token').delete();
      }
      await _refreshSub?.cancel();
    } on Exception catch (e) {
      developer.log('Falha ao remover token de push', error: e);
    }
  }
}
