import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/student_workout_provider.dart';
import '../widgets/workout_card.dart';
import 'workout_execution_page.dart';

/// Lista das divisões do treino atual do aluno (aberta pelo menu).
class MyWorkoutsPage extends ConsumerWidget {
  const MyWorkoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentWorkoutProvider);
    final workout = state.currentWorkout;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Meus treinos')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : workout == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Seu personal ainda não passou um treino para você.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(workout.name, style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Toque numa divisão para ver os exercícios e treinar.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ...workout.divisions.map(
                      (division) => WorkoutCard(
                        division: division,
                        lastCompletedDate: null,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutExecutionPage(division: division),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
