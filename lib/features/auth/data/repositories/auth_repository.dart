import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';

/// Erro de autenticação já traduzido para exibir ao usuário.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Acesso ao Firebase Auth, ao perfil em `users/{uid}` e às Cloud Functions
/// de cadastro. O papel do usuário (admin/trainer/student) vem SEMPRE do
/// custom claim `role`, definido no servidor; o documento `users/{uid}` é
/// só uma cópia para exibição.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Monta o perfil do usuário logado. Retorna `null` se a conta ainda não
  /// tem papel definido (ex.: criada no console sem convite).
  Future<UserEntity?> loadProfile(User user, {bool forceRefresh = false}) async {
    var role = await _readRole(user, forceRefresh: forceRefresh);

    // Conta sem papel: pode ser a conta admin recém-criada no console.
    // A função só concede o papel se o e-mail estiver na lista de admins.
    if (role == null) {
      try {
        await _functions.httpsCallable('claimAdmin').call<void>();
        role = await _readRole(user, forceRefresh: true);
      } on FirebaseFunctionsException {
        return null;
      }
    }
    if (role == null) return null;

    final snapshot = await _firestore.doc('users/${user.uid}').get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final createdAt = data['createdAt'];

    return UserEntity(
      id: user.uid,
      name: (data['name'] as String?) ??
          user.displayName ??
          user.email ??
          'Usuário',
      email: user.email ?? '',
      userType: UserTypeExtension.fromString(role),
      photoUrl: data['photoUrl'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      isActive: data['active'] as bool? ?? true,
    );
  }

  Future<String?> _readRole(User user, {required bool forceRefresh}) async {
    final token = await user.getIdTokenResult(forceRefresh);
    return token.claims?['role'] as String?;
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_translate(e));
    }
  }

  /// Cadastro avulso (fase de teste). A Cloud Function `completeSelfSignup`
  /// recusa se o admin tiver desligado o cadastro aberto; nesse caso a conta
  /// recém-criada é apagada para não ficar órfã.
  Future<UserEntity> signUp({
    required String name,
    required String email,
    required String password,
    required UserType userType,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_translate(e));
    }

    final user = credential.user!;
    try {
      await user.updateDisplayName(name);
      await _functions.httpsCallable('completeSelfSignup').call<void>({
        'name': name,
        'role': userType.value,
      });
    } on FirebaseFunctionsException catch (e) {
      await user.delete();
      throw AuthFailure(e.message ?? 'Não foi possível concluir o cadastro.');
    }

    final profile = await loadProfile(user, forceRefresh: true);
    if (profile == null) {
      throw const AuthFailure('Cadastro criado, mas o perfil não foi liberado.');
    }
    return profile;
  }

  /// Cadastro do aluno a partir do convite do personal: cria a conta e
  /// aceita o convite (vale mesmo com o cadastro aberto desligado).
  Future<UserEntity> signUpWithInvite({
    required String token,
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_translate(e));
    }

    final user = credential.user!;
    try {
      await user.updateDisplayName(name);
      await _acceptInvite(token);
    } on AuthFailure {
      await user.delete();
      rethrow;
    }

    final profile = await loadProfile(user, forceRefresh: true);
    if (profile == null) {
      throw const AuthFailure('Conta criada, mas o acesso não foi liberado.');
    }
    return profile;
  }

  /// Aluno já logado aceita um convite (ex.: trocou de personal).
  Future<UserEntity> acceptInviteAsCurrentUser(String token) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Faça login para aceitar o convite.');
    await _acceptInvite(token);
    final profile = await loadProfile(user, forceRefresh: true);
    if (profile == null) throw const AuthFailure('Acesso não liberado.');
    return profile;
  }

  Future<void> _acceptInvite(String token) async {
    try {
      await _functions
          .httpsCallable('acceptStudentInvite')
          .call<void>({'token': token});
    } on FirebaseFunctionsException catch (e) {
      throw AuthFailure(e.message ?? 'Não foi possível aceitar o convite.');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.setLanguageCode('pt');
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_translate(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _translate(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Esta conta está desativada. Fale com o seu personal.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail.';
      case 'weak-password':
        return 'Senha fraca: use pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente de novo.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro de autenticação (${e.code}).';
    }
  }
}
