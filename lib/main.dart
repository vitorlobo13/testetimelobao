import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'splash/splash_screen.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/trainer/presentation/pages/trainer_home_page.dart';
import 'features/student/presentation/pages/student_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar localização para datas em português
  await initializeDateFormatting('pt_BR', null);
  
  // Configurar orientação (somente portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // TODO: Inicializar Firebase
  // await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: TimeLobaoApp(),
    ),
  );
}

/// Aplicativo Principal Time Lobão
class TimeLobaoApp extends StatelessWidget {
  const TimeLobaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Lobão',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      
      // Localizações
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('pt', 'BR'),

      // Rotas
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/trainer/home': (context) => const TrainerHomePage(),
        '/student/home': (context) => const StudentHomePage(),
      },
    );
  }
}