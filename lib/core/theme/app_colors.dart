import 'package:flutter/material.dart';

/// Visual do app: Time Lobo (azul, do Matheus) ou Time Lopes (rosa, da
/// Thaísa). Cada aparelho guarda a escolha (ver team_theme_provider.dart).
enum TeamTheme {
  lobo('Time Lobo'),
  lopes('Time Lopes');

  const TeamTheme(this.label);
  final String label;

  TeamTheme get other => this == lobo ? lopes : lobo;
}

/// Cores que mudam de um visual para o outro.
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDeep,
    required this.accent,
    required this.accentLight,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.outline,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDeep;
  final Color accent;
  final Color accentLight;
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color outline;

  /// Azul elétrico do Matheus, com o rosa como destaque.
  static const lobo = AppPalette(
    primary: Color(0xFF2F7BFF),
    primaryLight: Color(0xFF6FA3FF),
    primaryDeep: Color(0xFF1B4FB8),
    accent: Color(0xFFE5337E),
    accentLight: Color(0xFFF27AAA),
    background: Color(0xFF0B1428),
    surface: Color(0xFF141F38),
    surfaceLight: Color(0xFF1E2B4A),
    outline: Color(0xFF2A3A5E),
  );

  /// Rosa da Thaísa sobre uma noite em tom de vinho.
  static const lopes = AppPalette(
    primary: Color(0xFFE5337E),
    primaryLight: Color(0xFFF27AAA),
    primaryDeep: Color(0xFFB01F5C),
    accent: Color(0xFFFF9EC7),
    accentLight: Color(0xFFFFC7DE),
    background: Color(0xFF1A0B16),
    surface: Color(0xFF2A1424),
    surfaceLight: Color(0xFF3A1D32),
    outline: Color(0xFF4E2944),
  );

  static AppPalette of(TeamTheme team) => team == TeamTheme.lopes ? lopes : lobo;
}

/// Paleta do Time Lobo Lopes.
///
/// As cores da marca e os fundos vêm do visual escolhido ([use]); por isso
/// são `get` e não `const`. Os nomes antigos (`blue`, `pink`, `teal`...)
/// continuam valendo: `blue`/`teal` é a cor principal do visual atual e
/// `pink` é a cor de destaque.
class AppColors {
  static TeamTheme _team = TeamTheme.lobo;
  static AppPalette _p = AppPalette.lobo;

  static TeamTheme get team => _team;

  /// Troca o visual. Quem chama precisa reconstruir o app (o MaterialApp
  /// usa o visual como key).
  static void use(TeamTheme team) {
    _team = team;
    _p = AppPalette.of(team);
  }

  // Marca (dinâmicas)
  static Color get blue => _p.primary; // cor principal (ação)
  static Color get blueLight => _p.primaryLight; // texto/realce
  static Color get blueDeep => _p.primaryDeep;
  static Color get pink => _p.accent; // destaque
  static Color get pinkLight => _p.accentLight;

  // Compatibilidade com o código existente
  static Color get teal => _p.primary;
  static Color get lightTeal => _p.primaryLight;
  static Color get darkTeal => _p.primaryDeep;
  static Color get info => _p.primaryLight;

  // Fundos (dinâmicos)
  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceLight => _p.surfaceLight;
  static Color get outline => _p.outline;

  // Cores fixas da marca, para mostrar os dois times lado a lado.
  static const Color loboBlue = Color(0xFF2F7BFF);
  static const Color lopesPink = Color(0xFFE5337E);

  // Textos
  static const Color textPrimary = Color(0xFFEEF2FA); // Gelo
  static const Color textSecondary = Color(0xFFA9B4CC); // Névoa clara
  static const Color textTertiary = Color(0xFF7483A3); // Névoa

  // Estados
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFF04452);
  static const Color warning = Color(0xFFF5A524);

  // "Gradientes": mantidos por compatibilidade, quase lisos.
  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_p.primaryDeep, _p.primary],
      );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC81E4A), Color(0xFFE5337E)],
  );

  // Sombras discretas (o contraste vem das superfícies, não de sombra)
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
