import 'package:flutter/material.dart';

/// Paleta de cores baseada na identidade visual Time Lobão
class AppColors {
  // Cores Primárias
  static const Color darkTeal = Color(0xFF0A4D4E); // Azul Petróleo Escuro
  static const Color teal = Color(0xFF0D7377); // Azul Petróleo Médio
  static const Color lightTeal = Color(0xFF14B8A6); // Azul Petróleo Claro (Acentos)

  // Fundos
  static const Color background = Color(0xFF0A0A0A); // Preto Profundo
  static const Color surface = Color(0xFF1A1A1A); // Cinza Grafite Escuro
  static const Color surfaceLight = Color(0xFF2A2A2A); // Cinza Grafite Médio

  // Textos
  static const Color textPrimary = Color(0xFFFFFFFF); // Branco
  static const Color textSecondary = Color(0xFFB0B0B0); // Cinza Claro
  static const Color textTertiary = Color(0xFF6B6B6B); // Cinza Médio

  // Estados
  static const Color success = Color(0xFF10B981); // Verde
  static const Color error = Color(0xFFEF4444); // Vermelho
  static const Color warning = Color(0xFFF59E0B); // Amarelo
  static const Color info = Color(0xFF3B82F6); // Azul

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkTeal, teal],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  );

  // Sombras
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: darkTeal.withOpacity(0.3),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}