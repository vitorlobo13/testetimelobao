import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/admin_home_page.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/student/presentation/pages/student_home_page.dart';
import '../../features/trainer/presentation/pages/trainer_home_page.dart';
import '../../splash/splash_screen.dart';

/// Caminhos das rotas principais. As telas internas continuam abrindo com
/// `Navigator.push` por cima destas rotas.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/cadastro';
  static const trainerHome = '/personal';
  static const studentHome = '/aluno';
  static const adminHome = '/admin';

  static const _public = {login, register};

  static String homeFor(UserType type) => switch (type) {
        UserType.trainer => trainerHome,
        UserType.student => studentHome,
        UserType.admin => adminHome,
      };
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Reavalia os redirecionamentos sempre que o estado de login mudar.
  final refresh = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen<AuthState>(authProvider, (_, next) => refresh.value = next);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = refresh.value;
      final location = state.matchedLocation;

      if (auth.isInitializing) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final user = auth.user;
      if (!auth.isAuthenticated || user == null) {
        return AppRoutes._public.contains(location) ? null : AppRoutes.login;
      }

      // Logado: cada papel só acessa a própria área.
      final home = AppRoutes.homeFor(user.userType);
      return location.startsWith(home) ? null : home;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.trainerHome,
        builder: (context, state) => const TrainerHomePage(),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (context, state) => const StudentHomePage(),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminHomePage(),
      ),
    ],
  );
});
