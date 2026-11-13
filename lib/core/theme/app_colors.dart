import 'package:flutter/material.dart';

/// Paleta do Time Lobo Lopes (tirada da identidade do Instagram):
/// noite azul-marinho, azul elétrico do Time Lobão e rosa do Time Thaísa Lopes.
///
/// Os nomes antigos (`teal`, `lightTeal`, `darkTeal`) continuam existindo
/// para não quebrar as telas: agora apontam para os tons de azul da marca.
class AppColors {
  // Marca
  static const Color blue = Color(0xFF2F7BFF); // Azul Lobão (ação principal)
  static const Color blueLight = Color(0xFF6FA3FF); // Azul claro (texto/realce)
  static const Color blueDeep = Color(0xFF1B4FB8); // Azul profundo
  static const Color pink = Color(0xFFE5337E); // Rosa Lopes (destaques)
  static const Color pinkLight = Color(0xFFF27AAA);

  // Compatibilidade com o código existente
  static const Color teal = blue;
  static const Color lightTeal = blueLight;
  static const Color darkTeal = blueDeep;

  // Fundos
  static const Color background = Color(0xFF0B1428); // Noite
  static const Color surface = Color(0xFF141F38); // Superfície
  static const Color surfaceLight = Color(0xFF1E2B4A); // Superfície elevada / bordas
  static const Color outline = Color(0xFF2A3A5E); // Bordas e divisórias

  // Textos
  static const Color textPrimary = Color(0xFFEEF2FA); // Gelo
  static const Color textSecondary = Color(0xFFA9B4CC); // Névoa clara
  static const Color textTertiary = Color(0xFF7483A3); // Névoa

  // Estados
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFF04452);
  static const Color warning = Color(0xFFF5A524);
  static const Color info = blueLight;

  // "Gradientes": mantidos por compatibilidade, agora quase lisos (sem o
  // visual chamativo de antes).
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B4FB8), Color(0xFF2F7BFF)],
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
