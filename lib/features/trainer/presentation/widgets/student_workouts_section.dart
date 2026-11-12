import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/entities/workout_entity.dart';
import '../pages/create_workout_page.dart';
import '../providers/trainer_provider.dart';
import '../providers/workout_builder_provider.dart';
import 'section_card.dart';

/// Treinos de um aluno, em tempo real (`studentLinks/{id}/workouts`).
final studentWorkoutsProvider =
    StreamProvider.family<List<WorkoutEntity>, String>(
  (ref, linkId) =>
      ref.watch(workoutRepositoryProvider).watchStudentWorkouts(linkId),
);

/// Treino atual + treinos anteriores do aluno, com editar, duplicar para
/// outro aluno e reativar um treino antigo.
class StudentWorkoutsSection extends ConsumerWidget {
  const StudentWorkoutsSection({super.key, required this.student});

  final StudentEntity student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(studentWorkoutsProvider(student.id));

    return workouts.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Erro ao carregar treinos: $e',
          style: AppTextStyles.bodyMedium),
      data: (list) {
        final active = list.where((w) => w.isActive).firstOrNull;
        final previous = list.where((w) => !w.isActive).toList();
        return Column(
          children: [
            SectionCard(
              title: 'Treino Atual',
              icon: Icons.fitness_center,
              actionLabel: active == null ? 'Prescrever' : 'Editar',
              onTap: () => _open(context, initial: active),
              child: active == null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text('Nenhum treino prescrito',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                    )
                  : _ActiveWorkout(
                      workout: active,
                      onDuplicate: () => _duplicate(context, ref, active),
                    ),
            ),
            if (previous.isNotEmpty) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: 'Treinos Anteriores',
                icon: Icons.inventory_2_outlined,
                child: Column(
                  children: [
                    for (final w in previous)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(w.name, style: AppTextStyles.bodyLarge),
                        subtitle: Text(
                          '${w.totalDivisions} divisões · ${w.totalExercises} exercícios'
                          ' · criado em ${DateFormat('dd/MM/yy').format(w.createdAt)}',
                          style: AppTextStyles.bodySmall,
                        ),
                        trailing: PopupMenuButton<String>(
                          color: AppColors.surface,
                          onSelected: (action) =>
                              _onPreviousAction(context, ref, w, action),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'reactivate', child: Text('Reativar')),
                            PopupMenuItem(
                                value: 'copy', child: Text('Usar como base')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Excluir')),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _open(BuildContext context,
      {WorkoutEntity? initial, StudentEntity? target, bool asCopy = false}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreateWorkoutPage(
        student: target ?? student,
        initialWorkout: initial,
        asCopy: asCopy,
      ),
    ));
  }

  Future<void> _duplicate(
      BuildContext context, WidgetRef ref, WorkoutEntity workout) async {
    final others = ref
        .read(trainerDashboardProvider)
        .students
        .where((s) => s.id != student.id && s.linkStatus != LinkStatus.archived)
        .toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cadastre outro aluno para duplicar este treino.'),
      ));
      return;
    }
    final target = await showModalBottomSheet<StudentEntity>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Duplicar para qual aluno?',
                  style: AppTextStyles.headlineSmall),
            ),
            for (final s in others)
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(s.name),
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );
    if (target != null && context.mounted) {
      _open(context, initial: workout, target: target, asCopy: true);
    }
  }

  Future<void> _onPreviousAction(BuildContext context, WidgetRef ref,
      WorkoutEntity workout, String action) async {
    final repo = ref.read(workoutRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (action) {
        case 'reactivate':
          await repo.reactivate(student.id, workout);
          messenger.showSnackBar(SnackBar(
            content: Text('"${workout.name}" voltou a ser o treino atual.'),
            backgroundColor: AppColors.success,
          ));
        case 'copy':
          _open(context, initial: workout, asCopy: true);
        case 'delete':
          await repo.delete(student.id, workout.id);
      }
    } on FirebaseException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro: ${e.message}'),
        backgroundColor: AppColors.error,
      ));
    }
  }
}

class _ActiveWorkout extends StatelessWidget {
  const _ActiveWorkout({required this.workout, required this.onDuplicate});

  final WorkoutEntity workout;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy');
    final end = workout.endDate;
    final validity = end == null
        ? 'Sem data de vencimento'
        : workout.isExpired
            ? 'Venceu em ${format.format(end)}'
            : 'Vence em ${format.format(end)}';
    final validityColor = workout.isExpired
        ? AppColors.error
        : workout.isExpiringSoon
            ? AppColors.warning
            : AppColors.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(workout.name, style: AppTextStyles.headlineSmall),
        if ((workout.description ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(workout.description!,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 8),
        Text(
          workout.divisions.map((d) => d.name).join(' · '),
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text('${workout.totalExercises} exercícios',
            style: AppTextStyles.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.event, size: 16, color: validityColor),
            const SizedBox(width: 6),
            Text(validity,
                style: AppTextStyles.bodySmall.copyWith(color: validityColor)),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.copy_all, size: 18),
            label: const Text('Duplicar para outro aluno'),
            onPressed: onDuplicate,
          ),
        ),
      ],
    );
  }
}
