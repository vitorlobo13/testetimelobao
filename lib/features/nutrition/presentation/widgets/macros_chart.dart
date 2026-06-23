import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Gráfico de macronutrientes
class MacrosChart extends StatelessWidget {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;
  final double? targetCalories;
  final double? targetProtein;
  final double? targetCarbs;
  final double? targetFats;

  const MacrosChart({
    super.key,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
    this.targetCalories,
    this.targetProtein,
    this.targetCarbs,
    this.targetFats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo Nutricional Diário',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Calorias
          _buildMacroBar(
            label: 'Calorias',
            value: totalCalories,
            target: targetCalories,
            unit: 'kcal',
            color: AppColors.warning,
          ),

          const SizedBox(height: 16),

          // Proteínas
          _buildMacroBar(
            label: 'Proteínas',
            value: totalProtein,
            target: targetProtein,
            unit: 'g',
            color: AppColors.error,
          ),

          const SizedBox(height: 16),

          // Carboidratos
          _buildMacroBar(
            label: 'Carboidratos',
            value: totalCarbs,
            target: targetCarbs,
            unit: 'g',
            color: AppColors.success,
          ),

          const SizedBox(height: 16),

          // Gorduras
          _buildMacroBar(
            label: 'Gorduras',
            value: totalFats,
            target: targetFats,
            unit: 'g',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar({
    required String label,
    required double value,
    double? target,
    required String unit,
    required Color color,
  }) {
    final percentage = target != null && target > 0 
        ? (value / target).clamp(0.0, 1.0) 
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              target != null
                  ? '${value.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit'
                  : '${value.toStringAsFixed(0)} $unit',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Barra de fundo
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Barra de progresso
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}