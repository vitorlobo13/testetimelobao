import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';

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

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordReset(email);
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }

  Future<void> logout() => _repository.signOut();

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
