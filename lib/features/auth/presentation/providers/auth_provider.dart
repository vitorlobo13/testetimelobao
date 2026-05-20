import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';

/// Estado de Autenticação
class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Se passar null aqui, ele limpa o erro
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Provider de Autenticação (Padrão Notifier)
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Estado inicial
    return const AuthState();
  }

  /// Fazer login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await Future.delayed(const Duration(seconds: 2));

      final user = UserEntity(
        id: '123',
        name: 'João Silva',
        email: email,
        userType: UserType.trainer,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao fazer login: ${e.toString()}',
      );
      return false;
    }
  }

  /// Registrar novo usuário
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserType userType,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await Future.delayed(const Duration(seconds: 2));

      final user = UserEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        userType: userType,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao registrar: ${e.toString()}',
      );
      return false;
    }
  }

Future<void> logout() async { 
  // sua lógica de limpar cache/token
}

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider global atualizado para o padrão NotifierProvider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});