import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../trainer/domain/entities/workout_entity.dart';
import '../../domain/entities/workout_session_entity.dart';
import '../providers/student_workout_provider.dart';
import '../widgets/exercise_execution_card.dart';
import '../widgets/timer_widget.dart';

/// Tela de execução do treino
class WorkoutExecutionPage extends ConsumerStatefulWidget {
  final WorkoutDivision division;

  const WorkoutExecutionPage({
    super.key,
    required this.division,
  });

  @override
  ConsumerState<WorkoutExecutionPage> createState() =>
      _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends ConsumerState<WorkoutExecutionPage> {
  int? _expandedExerciseIndex;
  bool _showTimer = false;
  int _timerDuration = 60;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Inicia a sessão de treino
    Future.microtask(() {
      ref.read(studentWorkoutProvider.notifier).startSession(widget.division.id);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showSetCompletionDialog(int exerciseIndex, int setIndex) {
    final workoutState = ref.read(studentWorkoutProvider);
    final session = workoutState.activeSession;
    if (session == null) return;

    final workoutExercise = widget.division.exercises[exerciseIndex];
    final repsController = TextEditingController();
    final loadController = TextEditingController(
      text: workoutExercise.load,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Série ${setIndex + 1}',
          style: AppTextStyles.headlineMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              workoutExercise.exercise.name,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Repetições realizadas',
              hint: workoutExercise.reps,
              controller: repsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: Icons.repeat,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Carga utilizada (kg)',
              hint: 'Ex: 20',
              controller: loadController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.fitness_center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final reps = int.tryParse(repsController.text);
              final load = double.tryParse(loadController.text);

              ref.read(studentWorkoutProvider.notifier).completeSet(
                    exerciseIndex,
                    setIndex,
                    reps: reps,
                    load: load,
                  );

              Navigator.pop(context);

              // Mostra timer de descanso
              if (workoutExercise.rest != null) {
                final restDuration = int.tryParse(workoutExercise.rest!) ?? 60;
                setState(() {
                  _timerDuration = restDuration;
                  _showTimer = true;
                });
              }
            },
            child: Text(
              'Concluir',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFinishDialog() async {
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Finalizar Treino?',
          style: AppTextStyles.headlineMedium,
        ),
        content: Text(
          'Você completou o treino! Deseja finalizar?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Continuar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Finalizar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldFinish == true && mounted) {
      await _finishWorkout();
    }
  }

  Future<void> _finishWorkout() async {
    final success = await ref.read(studentWorkoutProvider.notifier).finishSession();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treino finalizado com sucesso! 💪'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao finalizar treino'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showCancelDialog() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Cancelar Treino?',
          style: AppTextStyles.headlineMedium,
        ),
        content: Text(
          'Tem certeza que deseja cancelar? Todo o progresso será perdido.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Não',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sim, cancelar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldCancel == true && mounted) {
      ref.read(studentWorkoutProvider.notifier).cancelSession();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(studentWorkoutProvider);
    final session = workoutState.activeSession;

    if (session == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        ),
      );
    }

    final completionPercentage = session.completionPercentage;
    final isCompleted = completionPercentage == 100;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _showCancelDialog();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.division.name, style: AppTextStyles.headlineMedium),
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: _showCancelDialog,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Lista de exercícios
            ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Informações da sessão
                _buildSessionInfo(session),

                const SizedBox(height: 24),

                // Exercícios
                ...widget.division.exercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final workoutExercise = entry.value;
                  final exerciseSession = session.exerciseSessions[index];

                  return ExerciseExecutionCard(
                    workoutExercise: workoutExercise,
                    exerciseSession: exerciseSession,
                    isExpanded: _expandedExerciseIndex == index,
                    onToggleExpand: () {
                      setState(() {
                        _expandedExerciseIndex =
                            _expandedExerciseIndex == index ? null : index;
                      });
                    },
                    onSetComplete: (setIndex, reps, load) {
                      _showSetCompletionDialog(index, setIndex);
                    },
                  );
                }),

                const SizedBox(height: 100),
              ],
            ),

            // Timer de descanso
            if (_showTimer)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: TimerWidget(
                  durationSeconds: _timerDuration,
                  onComplete: () {
                    setState(() {
                      _showTimer = false;
                    });
                  },
                  onSkip: () {
                    setState(() {
                      _showTimer = false;
                    });
                  },
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.surfaceLight),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: CustomButton(
            text: isCompleted ? 'FINALIZAR TREINO' : 'EM PROGRESSO',
            onPressed: isCompleted ? _showFinishDialog : null,
            type: ButtonType.primary,
            icon: isCompleted ? Icons.check : Icons.fitness_center,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfo(WorkoutSessionEntity session) {
    final duration = session.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Treino em Andamento',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${session.completionPercentage.toStringAsFixed(0)}%',
            style: AppTextStyles.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.timer,
                label: 'Tempo',
                value: hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                icon: Icons.fitness_center,
                label: 'Exercícios',
                value:
                    '${session.exerciseSessions.where((e) => e.completed).length}/${session.exerciseSessions.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}