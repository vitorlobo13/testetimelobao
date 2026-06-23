import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../trainer/domain/entities/workout_entity.dart';

/// Card de divisão de treino para o aluno
class WorkoutCard extends StatelessWidget {
  final WorkoutDivision division;
  final VoidCallback onTap;
  final DateTime? lastCompletedDate;

  const WorkoutCard({
    super.key,
    required this.division,
    required this.onTap,
    this.lastCompletedDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.shadowLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        division.name,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      if (division.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          division.description!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Divisor
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),

            const SizedBox(height: 16),

            // Informações
            Row(
              children: [
                _buildInfo(
                  icon: Icons.list,
                  label: '${division.exercises.length} exercícios',
                ),
                const SizedBox(width: 24),
                if (lastCompletedDate != null)
                  _buildInfo(
                    icon: Icons.check_circle,
                    label: _getLastCompletedText(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getLastCompletedText() {
    if (lastCompletedDate == null) return 'Nunca realizado';

    final now = DateTime.now();
    final difference = now.difference(lastCompletedDate!);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${(difference.inDays / 7).floor()} semanas atrás';
    }
  }
}