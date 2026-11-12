import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Personal cadastrado, como o admin vê na lista.
class TrainerSummary {
  const TrainerSummary({
    required this.uid,
    required this.name,
    required this.email,
    required this.active,
  });

  final String uid;
  final String name;
  final String email;
  final bool active;

  factory TrainerSummary.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return TrainerSummary(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      active: data['active'] as bool? ?? true,
    );
  }
}

/// Operações da conta administradora: convidar e desativar personais e
/// ligar/desligar o cadastro aberto. Tudo que mexe em papel/conta passa por
/// Cloud Function; o app nunca grava papel direto.
class AdminRepository {
  AdminRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1'),
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> get _config =>
      _firestore.doc('config/app');

  Stream<List<TrainerSummary>> watchTrainers() => _firestore
      .collection('users')
      .where('role', isEqualTo: 'trainer')
      .snapshots()
      .map((snap) => snap.docs.map(TrainerSummary.fromDoc).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  /// Sem documento de configuração, o cadastro aberto vale como ligado
  /// (fase de teste) — mesma regra da Cloud Function.
  Stream<bool> watchSelfSignup() => _config
      .snapshots()
      .map((doc) => doc.data()?['allowSelfSignup'] as bool? ?? true);

  Future<void> setSelfSignup(bool allowed) =>
      _config.set({'allowSelfSignup': allowed}, SetOptions(merge: true));

  /// Cria (ou promove) a conta do personal e dispara o e-mail do Firebase
  /// para ele definir a própria senha.
  Future<void> inviteTrainer({required String name, required String email}) async {
    await _functions
        .httpsCallable('inviteTrainer')
        .call<void>({'name': name, 'email': email});
    await _auth.setLanguageCode('pt');
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> setTrainerActive({required String uid, required bool active}) =>
      _functions
          .httpsCallable('setTrainerActive')
          .call<void>({'uid': uid, 'active': active});
}
