import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/workout_session_entity.dart';
import '../providers/student_workout_provider.dart';

/// Tela de histórico de treinos do aluno
class WorkoutHistoryPage extends ConsumerWidget {
  const WorkoutHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(studentWorkoutProvider);
    final history = workoutState.history;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('HISTÓRICO DE TREINOS', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: history.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildStatsSummary(history),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final session = history[index];
                      return _HistoryCard(session: session);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum treino registrado',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Seus treinos finalizados aparecerão aqui para você acompanhar sua evolução.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(List<WorkoutSessionEntity> history) {
    final totalSessions = history.length;
    final totalDuration = history.fold<Duration>(
      Duration.zero,
      (sum, s) => sum + (s.endTime?.difference(s.startTime) ?? Duration.zero),
    );
    final totalMinutes = totalDuration.inMinutes;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            value: totalSessions.toString(),
            label: 'Treinos Realizados',
            icon: Icons.fitness_center,
            iconColor: AppColors.teal,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.surfaceLight,
          ),
          _buildStatItem(
            value: '${totalMinutes}m',
            label: 'Tempo Total',
            icon: Icons.timer,
            iconColor: AppColors.lightTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final WorkoutSessionEntity session;

  const _HistoryCard({required this.session});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(widget.session.startTime);
    final duration = widget.session.endTime?.difference(widget.session.startTime) ?? Duration.zero;
    final durationStr = '${duration.inMinutes} min';

    final workoutDivisionName = widget.session.divisionId == 'div_1'
        ? 'Treino A - Push'
        : widget.session.divisionId == 'div_2'
            ? 'Treino B - Pull'
            : 'Treino C - Legs';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.lightTeal,
                size: 24,
              ),
            ),
            title: Text(
              workoutDivisionName,
              style: AppTextStyles.headlineSmall,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(dateStr, style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                    const Icon(Icons.timer, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(durationStr, style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
            trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.textPrimary,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded) ...[
            const Divider(color: AppColors.surfaceLight, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXERCÍCIOS REALIZADOS',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.session.exerciseSessions.map((exSession) {
                    final exName = exSession.workoutExerciseId == 'ex_1'
                        ? 'Supino Reto com Barra'
                        : exSession.workoutExerciseId == 'ex_2'
                            ? 'Supino Inclinado com Halteres'
                            : exSession.workoutExerciseId == 'ex_3'
                                ? 'Desenvolvimento com Barra'
                                : exSession.workoutExerciseId == 'ex_4'
                                    ? 'Barra Fixa'
                                    : exSession.workoutExerciseId == 'ex_5'
                                        ? 'Remada Curvada'
                                        : 'Exercício de Treino';

                    final completedSetsCount = exSession.sets.where((s) => s.completed).length;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.arrow_right,
                            color: AppColors.lightTeal,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$completedSetsCount séries registradas',
                                  style: AppTextStyles.bodySmall,
                                ),
                                if (exSession.sets.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    children: exSession.sets.map((set) {
                                      final reps = set.actualReps ?? 0;
                                      final load = set.actualLoad ?? 0.0;
                                      return Chip(
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        backgroundColor: AppColors.surfaceLight,
                                        labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                        label: Text(
                                          'S${set.setNumber}: ${reps}x${load.toStringAsFixed(0)}kg',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                          side: BorderSide.none,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
