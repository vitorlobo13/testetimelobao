import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografia do Time Lobo Lopes:
/// - Barlow Condensed: títulos e números (o "esportivo" do logotipo);
/// - DM Serif Display (`voice`): momentos de destaque, como nos posts;
/// - Inter: todo o resto.
class AppTextStyles {
  // Títulos condensados (substituem a Bebas Neue)
  static TextStyle displayLarge = GoogleFonts.barlowCondensed(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.05,
  );

  static TextStyle displayMedium = GoogleFonts.barlowCondensed(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.4,
    height: 1.1,
  );

  static TextStyle displaySmall = GoogleFonts.barlowCondensed(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
    height: 1.1,
  );

  /// Serifa de destaque (saudação, telas de boas-vindas).
  static TextStyle voice = GoogleFonts.dmSerifDisplay(
    fontSize: 30,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  // Cabeçalhos
  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headlineSmall = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Corpo
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.35,
  );

  // Botões (sem espaçamento largo nem caixa-alta forçada)
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Labels
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );
}
