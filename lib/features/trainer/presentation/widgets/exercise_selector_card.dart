import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/exercise_entity.dart';

/// Card de seleção de exercício
class ExerciseSelectorCard extends StatelessWidget {
  final ExerciseEntity exercise;
  final VoidCallback onTap;
  final bool isSelected;

  const ExerciseSelectorCard({
    super.key,
    required this.exercise,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.teal.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Ícone do exercício
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getCategoryColor(exercise.category).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(exercise.category),
                color: _getCategoryColor(exercise.category),
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildBadge(exercise.muscleGroup, Colors.blue),
                      const SizedBox(width: 8),
                      _buildBadge(exercise.equipment, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),

            // Indicador de seleção
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.teal,
                size: 28,
              )
            else
              const Icon(
                Icons.add_circle_outline,
                color: AppColors.textTertiary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case ExerciseCategory.chest:
        return Colors.red;
      case ExerciseCategory.back:
        return Colors.blue;
      case ExerciseCategory.legs:
        return Colors.green;
      case ExerciseCategory.shoulders:
        return Colors.orange;
      case ExerciseCategory.biceps:
        return Colors.purple;
      case ExerciseCategory.triceps:
        return Colors.pink;
      case ExerciseCategory.abs:
        return Colors.yellow;
      default:
        return AppColors.teal;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case ExerciseCategory.chest:
        return Icons.fitness_center;
      case ExerciseCategory.back:
        return Icons.accessibility_new;
      case ExerciseCategory.legs:
        return Icons.directions_run;
      case ExerciseCategory.shoulders:
        return Icons.sports_gymnastics;
      case ExerciseCategory.biceps:
        return Icons.sports_martial_arts;
      case ExerciseCategory.triceps:
        return Icons.sports_kabaddi;
      case ExerciseCategory.abs:
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }
}