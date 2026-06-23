import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/meal_entity.dart';

/// Card de refeição
class MealCard extends StatelessWidget {
  final MealEntity meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isEditable;

  const MealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onDelete,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                // Ícone e horário
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getMealColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getMealIcon(),
                    color: _getMealColor(),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Nome e horário
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: AppTextStyles.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            meal.time,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botão deletar (modo edição)
                if (isEditable && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.error,
                    onPressed: onDelete,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Divisor
            const Divider(height: 1, color: AppColors.surfaceLight),

            const SizedBox(height: 16),

            // Macros
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem(
                  label: 'Calorias',
                  value: '${meal.totalCalories.toStringAsFixed(0)} kcal',
                  color: AppColors.warning,
                ),
                _buildMacroItem(
                  label: 'Proteínas',
                  value: '${meal.totalProtein.toStringAsFixed(0)}g',
                  color: AppColors.error,
                ),
                _buildMacroItem(
                  label: 'Carbs',
                  value: '${meal.totalCarbs.toStringAsFixed(0)}g',
                  color: AppColors.success,
                ),
                _buildMacroItem(
                  label: 'Gorduras',
                  value: '${meal.totalFats.toStringAsFixed(0)}g',
                  color: AppColors.info,
                ),
              ],
            ),

            // Lista de alimentos
            if (meal.foods.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.surfaceLight),
              const SizedBox(height: 12),
              Text(
                '${meal.foods.length} alimento(s)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],

            // Notas
            if (meal.notes != null && meal.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meal.notes!,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getMealColor() {
    switch (meal.order) {
      case 0:
        return AppColors.warning;
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.error;
      case 3:
        return AppColors.info;
      case 4:
        return AppColors.teal;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getMealIcon() {
    if (meal.name.toLowerCase().contains('café')) {
      return Icons.free_breakfast;
    } else if (meal.name.toLowerCase().contains('almoço')) {
      return Icons.lunch_dining;
    } else if (meal.name.toLowerCase().contains('jantar')) {
      return Icons.dinner_dining;
    } else if (meal.name.toLowerCase().contains('lanche')) {
      return Icons.fastfood;
    } else if (meal.name.toLowerCase().contains('pós')) {
      return Icons.local_drink;
    } else {
      return Icons.restaurant;
    }
  }
}