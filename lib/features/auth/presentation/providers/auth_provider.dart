import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../shared/notifications/push_service.dart';

/// Estado de Autenticação
class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  /// `true` até o Firebase informar se há sessão salva (usado pelo splash).
  final bool isInitializing;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
    this.isInitializing = false,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
    bool? isInitializing,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Se passar null aqui, ele limpa o erro
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Provider de Autenticação (Padrão Notifier) ligado ao Firebase Auth.
class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<User?>? _subscription;

  /// Durante o cadastro o Firebase avisa "logado" antes do papel existir;
  /// ignoramos esses eventos até o cadastro terminar.
  bool _registering = false;

  /// Mensagem a exibir depois que uma conta sem acesso é deslogada.
  String? _pendingError;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    _subscription = _repository.authStateChanges().listen(_onAuthChanged);
    ref.onDispose(() => _subscription?.cancel());
    return const AuthState(isInitializing: true);
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (_registering) return;

    if (firebaseUser == null) {
      state = AuthState(errorMessage: _pendingError);
      _pendingError = null;
      return;
    }

    try {
      final profile = await _repository.loadProfile(firebaseUser);
      if (profile == null) {
        _pendingError = 'Sua conta ainda não tem acesso liberado. '
            'Peça um convite ao seu personal.';
        await _repository.signOut();
        return;
      }
      state = AuthState(user: profile, isAuthenticated: true);
    } on FirebaseException catch (e) {
      state = AuthState(errorMessage: 'Erro ao carregar perfil: ${e.message}');
    }
  }

  /// Fazer login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signIn(email: email, password: password);
      // O perfil chega pelo listener de authStateChanges; esperamos por ele.
      await _waitForProfile();
      return state.isAuthenticated;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  /// Registrar novo usuário (cadastro avulso da fase de teste)
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserType userType,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    _registering = true;
    try {
      final profile = await _repository.signUp(
        name: name,
        email: email,
        password: password,
        userType: userType,
      );
      state = AuthState(user: profile, isAuthenticated: true);
      return true;
    } on AuthFailure catch (e) {
      state = AuthState(errorMessage: e.message);
      return false;
    } finally {
      _registering = false;
    }
  }

  /// Aluno novo criando a conta pelo link de convite.
  Future<bool> registerWithInvite({
    required String token,
    required String name,
    required String email,
    required String password,
  }) =>
      _runRegistration(() => _repository.signUpWithInvite(
            token: token,
            name: name,
            email: email,
            password: password,
          ));

  /// Aluno já logado aceitando um convite novo.
  Future<bool> acceptInvite(String token) =>
      _runRegistration(() => _repository.acceptInviteAsCurrentUser(token));

  Future<bool> _runRegistration(Future<UserEntity> Function() action) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    _registering = true;
    try {
      final profile = await action();
      state = AuthState(user: profile, isAuthenticated: true);
      return true;
    } on AuthFailure catch (e) {
      // Mantém a sessão se o aluno já estava logado; só mostra o erro.
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } finally {
      _registering = false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordReset(email);
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    // Este aparelho para de receber push da conta que está saindo.
    // No celular isso pode demorar (rede lenta, push do navegador); não
    // deixamos segurar a saída por mais de 3 segundos.
    final uid = state.user?.id;
    if (uid != null) {
      try {
        await PushService()
            .unregister(uid)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    await _repository.signOut();
  }

  /// Salva nome/telefone e já reflete no estado (sem recarregar a sessão).
  Future<void> updateProfile({required String name, String? phone}) async {
    await _repository.updateProfile(name: name, phone: phone);
    final user = state.user;
    if (user != null) {
      state = state.copyWith(
          user: user.copyWith(name: name.trim(), phone: phone?.trim() ?? ''));
    }
  }

  Future<void> updatePhoto(String? url) async {
    await _repository.updatePhoto(url);
    final user = state.user;
    if (user != null) {
      state = state.copyWith(
          user: url == null
              ? user.copyWith(clearPhoto: true)
              : user.copyWith(photoUrl: url));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _repository.changePassword(
          currentPassword: currentPassword, newPassword: newPassword);

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> _waitForProfile() async {
    for (var i = 0; i < 50 && !state.isAuthenticated; i++) {
      if (state.errorMessage != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}

/// Provider global atualizado para o padrão NotifierProvider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
