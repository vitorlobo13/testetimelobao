import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // URLs limpas na web (/convite/abc em vez de /#/convite/abc)
  usePathUrlStrategy();
  
  // Inicializar localização para datas em português
  await initializeDateFormatting('pt_BR', null);
  
  // Configurar orientação (somente portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: TimeLobaoApp(),
    ),
  );
}

/// Aplicativo principal Time Lobo Lopes
class TimeLobaoApp extends ConsumerWidget {
  const TimeLobaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Time Lobo Lopes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: ref.watch(appRouterProvider),

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
    );
  }
}