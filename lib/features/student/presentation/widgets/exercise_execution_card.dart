import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../trainer/domain/entities/workout_entity.dart';
import '../../domain/entities/workout_session_entity.dart';

/// Card de exercício durante execução
class ExerciseExecutionCard extends StatelessWidget {
  final WorkoutExercise workoutExercise;
  final ExerciseSessionEntity exerciseSession;
  final Function(int setIndex, int? reps, double? load) onSetComplete;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const ExerciseExecutionCard({
    super.key,
    required this.workoutExercise,
    required this.exerciseSession,
    required this.onSetComplete,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: exerciseSession.completed 
              ? AppColors.success 
              : AppColors.surfaceLight,
          width: exerciseSession.completed ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Cabeçalho
          InkWell(
            onTap: onToggleExpand,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ícone de status
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: exerciseSession.completed
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.teal.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      exerciseSession.completed
                          ? Icons.check_circle
                          : Icons.fitness_center,
                      color: exerciseSession.completed
                          ? AppColors.success
                          : AppColors.teal,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Nome e informações
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workoutExercise.exercise.name,
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exerciseSession.completedSets}/${workoutExercise.sets} séries',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ícone expandir
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Detalhes expandidos
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.surfaceLight),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações do exercício
                  _buildInfoRow(
                    icon: Icons.repeat,
                    label: 'Repetições',
                    value: workoutExercise.reps,
                  ),
                  if (workoutExercise.rest != null)
                    _buildInfoRow(
                      icon: Icons.timer,
                      label: 'Descanso',
                      value: '${workoutExercise.rest}s',
                    ),
                  if (workoutExercise.load != null)
                    _buildInfoRow(
                      icon: Icons.fitness_center,
                      label: 'Carga sugerida',
                      value: '${workoutExercise.load} kg',
                    ),
                  if (workoutExercise.notes != null) ...[
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
                            size: 18,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              workoutExercise.notes!,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Lista de séries
                  ...exerciseSession.sets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final set = entry.value;
                    return _buildSetRow(index, set);
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int index, SetSessionEntity set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: set.completed
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: set.completed ? AppColors.success : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Número da série
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: set.completed
                  ? AppColors.success
                  : AppColors.teal.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${set.setNumber}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: set.completed ? Colors.white : AppColors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Informações da série
          Expanded(
            child: set.completed
                ? Text(
                    '${set.actualReps ?? '-'} reps${set.actualLoad != null ? ' • ${set.actualLoad} kg' : ''}',
                    style: AppTextStyles.bodyMedium,
                  )
                : Text(
                    'Toque para completar',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
          ),

          // Botão/Status
          if (set.completed)
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24,
            )
          else
            IconButton(
              onPressed: () => _showSetCompletionDialog(index),
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.teal,
            ),
        ],
      ),
    );
  }

  void _showSetCompletionDialog(int setIndex) {
    // Será implementado na página de execução
  }
}