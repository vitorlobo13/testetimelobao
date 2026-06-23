import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/meal_entity.dart';

/// Card de alimento individual
class FoodItemCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onDelete;

  const FoodItemCard({
    super.key,
    required this.food,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${food.quantity} ${food.unit}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.error,
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Macros em linha
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildMacroChip(
                label: '${food.calories.toStringAsFixed(0)} kcal',
                color: AppColors.warning,
              ),
              _buildMacroChip(
                label: 'P: ${food.protein.toStringAsFixed(0)}g',
                color: AppColors.error,
              ),
              _buildMacroChip(
                label: 'C: ${food.carbs.toStringAsFixed(0)}g',
                color: AppColors.success,
              ),
              _buildMacroChip(
                label: 'G: ${food.fats.toStringAsFixed(0)}g',
                color: AppColors.info,
              ),
            ],
          ),

          // Notas
          if (food.notes != null && food.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              food.notes!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}